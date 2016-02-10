=begin rdoc
--------------------------------------------------------------------------------

Build the Solr index from the triple-store, optionally clearing it first.

Keeps a bookmark in case of interruption, so we can resume without restarting.
You may choose to ignore the bookmark, to start again.

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module Indexing
    class BuildSolrIndex
      include Utilities::MainClassHelper
      include Utilities::TripleStoreUser
      include Utilities::SolrServerUser

      QUERY_FIND_AGENTS = <<-END
      PREFIX foaf: <http://xmlns.com/foaf/0.1/>
      SELECT ?uri
      WHERE {
        GRAPH ?g {
          { 
            ?uri a foaf:Person .
          } UNION {
            ?uri a foaf:Organization .
          } 
        }
      }
      END
      QUERY_FIND_WORKS = <<-END
      PREFIX ld4l: <http://bib.ld4l.org/ontology/>
      SELECT ?uri
      WHERE {
        GRAPH ?g { 
          ?uri a ld4l:Work .
        } 
      }
      END
      QUERY_FIND_INSTANCES = <<-END
      PREFIX ld4l: <http://bib.ld4l.org/ontology/>
      SELECT ?uri
      WHERE {
        GRAPH ?g { 
          ?uri a ld4l:Instance .
        } 
      }
      END

      TYPES = [
        {:id => :work, :query => QUERY_FIND_WORKS},
        {:id => :instance, :query => QUERY_FIND_INSTANCES},
        {:id => :agent, :query => QUERY_FIND_AGENTS}
      ]

      URI_BATCH_LIMIT = 1000

      def initialize
        @usage_text = [
          'Usage is ld4l_build_solr_index \\',
          'report=<report_file>[~REPLACE] \\',
          'IGNORE_BOOKMARKS \\',
          'CLEAR_INDEX \\',
          'IGNORE_SITE_SURPRISES \\',
        ]
      end

      def process_arguments()
        parse_arguments(:report, :IGNORE_BOOKMARKS, :CLEAR_INDEX, :IGNORE_SITE_SURPRISES)
        @report = Report.new('ld4l_build_solr_index', validate_output_file(:report, "report file"))
        @ignore_bookmarks = @args[:IGNORE_BOOKMARKS]
        @ignore_surprises = @args[:IGNORE_SITE_SURPRISES]
        @clear_index = @args[:CLEAR_INDEX]
        @report.log_header
      end

      def check_for_surprises
        check_site_consistency(@ignore_surprises, {
          'Triple store' => @ts,
          'Report path' => @report
        })
      end

      def prepare_document_factory
        @doc_factory = IndexDocuments::DocumentFactory.new(@ts)
      end

      def initialize_bookmark
        @bookmark = Bookmark.new('build_solr_index', @ss, @ignore_bookmarks)
      end

      def trap_control_c
        @interrupted = false
        trap("SIGINT") do
          @interrupted = true
        end
      end

      def query_and_index_items()
        bindings = @graph ? {'g' => @graph} : {}
        uris = UriDiscoverer.new(@bookmark, @ts, @report, TYPES, URI_BATCH_LIMIT, bindings)
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
          check_for_surprises
          initialize_bookmark
          trap_control_c

          @report.record_counts(Counts.new(@ts, @graph))
          query_and_index_items

          @report.summarize(@doc_factory, @bookmark)
          @ss.commit
        rescue UserInputError, IllegalStateError
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
