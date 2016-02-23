=begin

Provide a way to bind variables in a query, and to execute the query.
Execution is through either select() or construct().

For a SELECT query, the triple-store must return a JSON-formatted response. The
select() method will parse that and return an array of hashes.

Example:
[
  {'p' => 'http://first/predicate', 'o' => 'http://first/object' },
  {'p' => 'http://second/predicate', 'o' => 'http://second/object' }
]

For a CONSTRUCT query, the triple-store must return NTriples. The construct()
method will return an RDF:Graph containing the results.

=end

module Ld4lBrowserData
  module Utilities
    module TripleStoreUser
      class QueryRunner
        LD4L_PREFIX = 'http://draft.ld4l.org'
        #
        def initialize(query)
          @initial_query = String.new(query)
          @query = String.new(query)
        end

        def bind_uri(varname, value)
          @query.gsub!(Regexp.new("\\?#{varname}\\b"), "<#{value}>")
          self
        end

        def bind_graph(varname, uri)
          graph = graph_from_uri(uri)
          if graph
            bind_uri(varname, graph)
          else
            puts "Could not bind graph for #{uri} -- ignored."
          end
          self
        end

        def select(ts)
          begin
            ts.sparql_query(@query) do |resp|
              return parse_response(resp)
            end
          rescue
            puts "FAILING QUERY: " + @query
            raise $!
          end
        end

        def parse_response(resp)
          JSON.parse(resp.body)['results']['bindings'].map do |row|
            parse_row(row)
          end
        end

        def parse_row(row)
          Hash[row.map { |k, v| [k, v['value']] }]
        end

        def construct(ts)
          result = nil
          ts.sparql_query(@query, 'text/plain') do |resp|
            result = RDF::Graph.new << RDF::Reader.for(:ntriples).new(resp.body)
          end
          result
        end

        def graph_from_uri(uri)
          if uri.start_with?'http://draft.ld4l.org'
            parts = uri.split('/')
            if %w(cornell harvard stanford).include?(parts[-2])
              return parts[0..-2].join('/')
            end
          end
          nil
        end
      end
    end
  end
end
