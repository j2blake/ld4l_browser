=begin rdoc
--------------------------------------------------------------------------------

Build new Solr index records for a specific set of URIs. If the URI doesn't
represent a Work, Instance, or Agent, it will be noted and ignored.

Specify a directory that holds lists of uris, and a place to put the report.

--------------------------------------------------------------------------------
=end
require_relative 'index_specific_uris/bookmark'
require_relative 'index_specific_uris/report'
require_relative 'index_specific_uris/uri_discoverer'

module Ld4lBrowserData
  module Indexing
    class IndexSpecificUris
      include Utilities::MainClassHelper
      include Utilities::TripleStoreUser
      include Utilities::SolrServerUser
      def initialize
        @usage_text = [
          'Usage is ld4l_index_specific_uris \\',
          'source=<source_directory> \\',
          'report=<report_file>[~REPLACE] \\',
          'IGNORE_BOOKMARKS \\',
          'CLEAR_INDEX \\',
          'IGNORE_SITE_SURPRISES \\',
        ]
      end

      def process_arguments()
        parse_arguments(:source, :report, :IGNORE_BOOKMARKS, :CLEAR_INDEX, :IGNORE_SITE_SURPRISES)
        @source_dir = validate_input_directory(:source, "source_directory")
        @report = Report.new(validate_output_file(:report, "report file"))
        @ignore_bookmarks = @args[:IGNORE_BOOKMARKS]
        @ignore_surprises = @args[:IGNORE_SITE_SURPRISES]
        @clear_index = @args[:CLEAR_INDEX]
        @report.log_header
      end

      def check_for_surprises
        check_site_consistency(@ignore_surprises, {
          'Triple store' => @ts,
          'Report path' => @report,
          'Source directory' => @source_dir
        })
      end

      def prepare_document_factory
        @doc_factory = IndexDocuments::DocumentFactory.new(@ts)
      end

      def do_it
        uris = UriDiscoverer.new(@bookmark, @ts, @report, @source_dir)
        uris.each do |type, uri|
          if @interrupted
            process_interruption
            raise UserInputError.new("INTERRUPTED")
          else
            begin
              doc = @doc_factory.document(type, uri)
              @ss.add_document(doc.document) if doc
            rescue DocumentError
              @report.log_document_error(type, uri, $!.doc, $!.cause)
            rescue
              @report.log_document_error(type, uri, doc, $!)
            end
          end
        end
      end

      def initialize_bookmark
        @bookmark = Bookmark.new(File.basename(@source_dir), @ss, @ignore_bookmarks)
      end

      def trap_control_c
        @interrupted = false
        trap("SIGINT") do
          @interrupted = true
        end
      end

      def process_interruption
        @ss.commit
        @bookmark.persist
        @report.summarize(@doc_factory, @bookmark, :interrupted)
      end

      def run()
        begin
          process_arguments
          connect_solr_server(@clear_index)
          connect_triple_store
          prepare_document_factory
          initialize_bookmark
          trap_control_c

          do_it

          @report.summarize(@doc_factory, @bookmark)
          @ss.commit
          @bookmark.complete
        rescue UserInputError
          puts
          puts "ERROR: #{$!}"
          puts
        ensure
          @report.close if @report
        end
      end
    end
  end
end