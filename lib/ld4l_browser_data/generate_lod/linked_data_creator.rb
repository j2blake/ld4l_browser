=begin rdoc
--------------------------------------------------------------------------------

Generate files of Linked Open Data from the triple-store, for the LOD server.
The files are created in a nested directory structure, in TTL format. When
servicing a request, the server will read the file into a graph, add document
triples, and serialize it to the requested format.

--------------------------------------------------------------------------------

Usage: ld4l_create_lod_files <source_dir> <target_dir> [RESTART] <report_file> [REPLACE]

--------------------------------------------------------------------------------
=end
require_relative 'linked_data_creator/report'

module Ld4lBrowserData
  module GenerateLod
    class LinkedDataCreator
      include Utilities::FileSystemUser
      include Utilities::MainClassHelper
      include Utilities::TripleStoreUser
      def initialize
        @usage_text = [
          'Usage is ld4l_create_lod_files \\',
          'source=<source_directory> \\',
          'file_system=<file_system_key>[~REPLACE] \\',
          'report=<report_file>[~REPLACE] \\',
          'IGNORE_BOOKMARK \\',
          'IGNORE_SITE_SURPRISES \\',
        ]

        @uri_prefix = 'http://draft.ld4l.org/'
      end

      def process_arguments()
        parse_arguments(:source, :file_system, :report, :IGNORE_BOOKMARK, :IGNORE_SITE_SURPRISES)
        @source_dir = validate_input_directory(:source, "source_directory")
        @files = validate_file_system(:file_system, "file system key")
        @report = Report.new('ld4l_create_lod_files', validate_output_file(:report, "report file"))
        @ignore_bookmark = @args[:IGNORE_BOOKMARK]
        @ignore_surprises = @args[:IGNORE_SITE_SURPRISES]
        @report.log_header
      end

      def check_for_surprises
        check_site_consistency(@ignore_surprises, {
          'Triple store' => @ts,
          'Source directory' => @source_dir,
          'File system' => @files,
          'Report path' => @report
        })
      end

      def initialize_bookmark
        @bookmark = Bookmark.new(File.basename(@source_dir), @files, @ignore_bookmark)
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
        @uris = UriDiscoverer.new(@ts, @source_dir, @bookmark, @report)
        @uris.each do |uri|
          if @interrupted
            process_interruption
            break
          else
            begin
              UriProcessor.new(@ts, @files, @report, uri).run
            rescue
              process_exception
              break
            end
          end
        end
        @report.summarize(@bookmark, :complete)
        @report.logit("Complete")
      end

      def process_interruption
        @bookmark.persist
        @report.summarize(@bookmark, :interrupted)
      end

      def process_exception
        @bookmark.persist
        @report.summarize(@bookmark, :exception)
      end

      def place_void_files
        source_dir = File.expand_path('../void',__FILE__)
        Dir.chdir(source_dir) do |dir|
          Dir.foreach('.') do |filename|
            @files.set_void(filename, File.read(filename)) if filename.start_with? 'void'
          end
        end
      end

      def report
        @report.stats
      end

      def setup()
        process_arguments
        connect_triple_store
#        connect_file_system
        initialize_bookmark
        trap_control_c
      end

      def run
        begin
          setup
          iterate_through_uris
          place_void_files
          report
        rescue UserInputError, IllegalStateError, SettingsError
          puts
          puts "ERROR: #{$!}"
          puts
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
