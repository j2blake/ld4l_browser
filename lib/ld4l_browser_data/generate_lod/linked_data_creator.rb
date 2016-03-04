=begin rdoc
--------------------------------------------------------------------------------

Generate files of Linked Open Data from the triple-store, for the LOD server.
The files are created in a nested directory structure, in TTL format. When
servicing a request, the server will read the file into a graph, add document
triples, and serialize it to the requested format.

--------------------------------------------------------------------------------
=end
require_relative 'linked_data_creator/report'
require_relative 'linked_data_creator/uri_processor'

module Ld4lBrowserData
  module GenerateLod
    class LinkedDataCreator
      include Utilities::FileSystemUser
      include Utilities::MainClassHelper
      include Utilities::TripleStoreUser
      def initialize
        @usage_text = [
          'Usage is ld4l_create_lod_files \\',
          'source=<source_file_or_directory> \\',
          'file_system=<file_system_key>[~REPLACE] \\',
          'report=<report_file>[~REPLACE] \\',
          '[IGNORE_BOOKMARK] \\',
          '[IGNORE_SITE_SURPRISES] \\',
        ]

        @uri_prefix = 'http://draft.ld4l.org/'
      end

      def process_arguments()
        parse_arguments(:source, :file_system, :report, :IGNORE_BOOKMARK, :IGNORE_SITE_SURPRISES)
        @source_files = SourceFiles.new(validate_input_source(:source, "source_file_or_directory"))
        @files = validate_file_system(:file_system, "file system key")
        @report = Report.new('ld4l_create_lod_files', validate_output_file(:report, "report file"))
        @ignore_bookmark = @args[:IGNORE_BOOKMARK]
        @ignore_surprises = @args[:IGNORE_SITE_SURPRISES]
        @report.log_header
      end

      def check_for_surprises
        check_site_consistency(@ignore_surprises, {
          'Triple store' => @ts,
          'Source file or directory' => @source_files,
          'File system' => @files,
          'Report path' => @report
        })
      end

      def initialize_bookmark
        @bookmark = Bookmark.new(@source_files.basename, @files, @ignore_bookmark)
        @report.log_bookmark(@bookmark)
      end

      def trap_control_c
        @interrupted = false
        trap("SIGINT") do
          @interrupted = true
        end
      end

      def iterate_through_uris
        puts "Beginning processing. Press ^c to interrupt."
        @uris = UriDiscoverer.new(@ts, @source_files, @bookmark, @report)
        @uris.each do |uri|
          if @interrupted
            @report.summarize(@bookmark, :interrupted)
            break
          else
            begin
              UriProcessor.new(@ts, @files, @report, uri).run
            rescue
              @report.summarize(@bookmark, :exception)
              raise $!
            end
          end
        end
        @report.summarize(@bookmark, :complete)
        @report.logit("Complete")
      end

      def place_void_files
        void_dir = File.expand_path('../void',__FILE__)
        Dir.chdir(void_dir) do |dir|
          Dir.foreach('.') do |filename|
            if filename.start_with?('void_') && filename.end_with?('.ttl')
            uri = @uri_prefix + filename[5..-5]
            content = File.read(filename)
            @files.write(uri, content)
          end
          end
        end
      end

      def report
        @report.stats
      end

      def setup()
        process_arguments
        connect_triple_store
        initialize_bookmark
        trap_control_c
      end

      def run
        begin
          setup
          iterate_through_uris
          place_void_files
          report
          exit 1 if @interrupted
        rescue UserInputError, IllegalStateError, SettingsError
          puts
          puts "ERROR: #{$!}"
          puts
          exit 1
        ensure
          @files.close if @files
          if @report
            @report.summarize_http_status(@ts)
            @report.close
          end
        end
      end
    end
  end
end
