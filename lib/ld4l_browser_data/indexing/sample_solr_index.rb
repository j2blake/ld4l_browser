=begin rdoc
--------------------------------------------------------------------------------

Select a well-connected sample of the triple-store and build Solr index records
for them.

Specify the number of Works to index, and the routine will also index any related
Indexes and Agents.

--------------------------------------------------------------------------------
=end
require_relative 'sample_solr_index/uri_discoverer'

module Ld4lBrowserData
  module Indexing
    class SampleSolrIndex
      include Utilities::MainClassHelper
      include Utilities::TripleStoreUser
      include Utilities::SolrServerUser
      def initialize
        @usage_text = [
          'Usage is ld4l_sample_solr_index \\',
          'works=<number_of_works> \\',
          'report=<report_file>[~REPLACE] \\',
          '[CLEAR_INDEX] \\',
          '[IGNORE_SITE_SURPRISES] \\',
        ]
      end

      def process_arguments()
        parse_arguments(:report, :works, :CLEAR_INDEX, :IGNORE_SITE_SURPRISES)
        @report = Report.new('ld4l_sample_solr_index', validate_output_file(:report, "report file"))
        @number_of_works = validate_integer(:key => :works, :label => "number of works", :min => 1 )
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

      def index_works()
        uris = UriDiscoverer.new(@ts, @report, 500)
        uris.first(@number_of_works).each do |uri|
          begin
            if @interrupted
              process_interruption
              raise UserInputError.new("INTERRUPTED")
            else
              begin
                doc = @doc_factory.document(:work, uri)
                if doc
                  @ss.add_document(doc.document)
                  index_instances(doc.values["instances"])
                  index_agents(doc.values['creators'])
                  index_agents(doc.values['contributors'])
                end
              rescue
                @report.log_document_error(:work, uri, doc, $!)
              end
            end
          end
        end
      end

      def index_instances(instances)
        instances.each do |instance|
          uri = instance[:uri]
          begin
            doc = @doc_factory.document(:instance, uri)
            if doc
              @ss.add_document(doc.document)
            end
          rescue
            @report.log_document_error(:instance, uri, doc, $!)
          end
        end
      end

      def index_agents(agents)
        agents.each do |agent|
          uri = agent[:uri]
          begin
            doc = @doc_factory.document(:agent, uri)
            if doc
              @ss.add_document(doc.document)
            end
          rescue
            @report.log_document_error(:agent, uri, doc, $!)
          end
        end
      end

      def trap_control_c
        @interrupted = false
        trap("SIGINT") do
          @interrupted = true
        end
      end

      def process_interruption
        @ss.commit
        @report.summarize(@doc_factory, :interrupted)
      end

      def run()
        begin
          process_arguments
          @report.log_header

          connect_solr_server(@clear_index)
          connect_triple_store
          check_for_surprises
          prepare_document_factory
          trap_control_c

          @report.record_counts(Counts.new(@ts, @graph))
          index_works
          @report.summarize(@doc_factory)
          @ss.commit
        rescue UserInputError
          puts
          puts "ERROR: #{$!}"
          puts
          exit 1
        ensure
          @report.close if @report
        end
      end
    end
  end
end
