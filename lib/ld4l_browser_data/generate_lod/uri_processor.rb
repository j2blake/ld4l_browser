=begin
--------------------------------------------------------------------------------

Process one URI, fetching the relevant triples from the triple-store, recording
stats, and writing an N3 file.

--------------------------------------------------------------------------------
=end
require "ruby-xxhash"

module Ld4lBrowserData
  module GenerateLod
    class ErrorMonitor
      def initialize
        @error_count = 0
        @latest = nil
      end

      def good
        @error_count = 0
        @latest = nil
      end

      def bad
        @error_count += 1
        @latest = nil
        check_it
      end

      def failed
        @error_count += 1
        @latest = $!
        check_it
      end

      def check_it
        if @error_count >= 5
          if @latest
            puts @latest
            puts @latest.backtrace.join("\n")
          end
          raise IllegalStateError.new("Too many consecutive failures.")
        end
      end
    end

    class UriProcessor
      include Utilities::TripleStoreUser

      @@error_monitor = ErrorMonitor.new

      QUERY_OUTGOING = <<-END
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        CONSTRUCT {
          ?uri ?p ?o .
          ?o a ?type .
          ?o rdfs:label ?label . 
          ?o skos:prefLabel ?prefLabel . 
        }
        WHERE { 
          GRAPH ?g {
            ?uri ?p ?o . 
            OPTIONAL {
              ?o a ?type .
            } 
            OPTIONAL {
              ?o rdfs:label ?label . 
            } 
            OPTIONAL {
              ?o skos:prefLabel ?prefLabel . 
            }
          } 
        }
      END

      QUERY_INCOMING = <<-END
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        CONSTRUCT {
          ?s ?p ?uri .
          ?s a ?type . 
          ?s rdfs:label ?label . 
          ?s skos:prefLabel ?prefLabel . 
        }
        WHERE { 
          GRAPH ?g {
            ?s ?p ?uri .
            OPTIONAL {
              ?s a ?type . 
            } 
            OPTIONAL {
              ?s rdfs:label ?label . 
            } 
            OPTIONAL {
              ?s skos:prefLabel ?prefLabel . 
            }
          } 
        }
      END
      #
      def initialize(ts, files, report, uri)
        @ts = ts
        @files = files
        @report = report
        @uri = uri
        @digest = Digest::XXHash.new(64)
      end

      def build_the_graph
        @graph = RDF::Graph.new
        @graph << QueryRunner.new(QUERY_OUTGOING).bind_graph('g', @uri).bind_uri('uri', @uri).construct(@ts)
        @graph << QueryRunner.new(QUERY_INCOMING).bind_graph('g', @uri).bind_uri('uri', @uri).construct(@ts)
      end

      def write_it_out
        @content = RDF::Writer.for(file_extension: "ttl").buffer do |writer|
          writer << @graph
        end
        @files.write(@uri, @content)
      end

      def run()
        begin
          if (@files.acceptable?(@uri))
            build_the_graph
            write_it_out
            @report.wrote_it(@uri, @graph, @content)
            @@error_monitor.good
          else
            @report.bad_uri(@uri)
            @@error_monitor.bad
          end
        rescue
          @report.uri_failed(@uri, $!)
          @@error_monitor.failed
        end
      end
    end
  end
end
