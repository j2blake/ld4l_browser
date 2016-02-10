=begin
--------------------------------------------------------------------------------

Repeatedly get bunches of URIs for Works. Dispense them one at a time.

The query should return the uris in ?uri, and should not contain an OFFSET or
LIMIT, since they will be added here.

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module Indexing
    class SampleSolrIndex
      class UriDiscoverer
        include Enumerable

        QUERY_FIND_WORKS = <<-END
        PREFIX ld4l: <http://bib.ld4l.org/ontology/>
        SELECT ?uri
        WHERE { 
          ?uri a ld4l:Work .
        }
        END
        def initialize(ts, report, limit)
          @ts = ts
          @report = report
          @limit = limit
          @uris = []
          @offset = 0
        end

        def each()
          while true
            replenish_buffer if @uris.empty?
            if @uris.empty?
              return
            end

            yield @uris.shift
            @offset += 1
          end
        end

        def replenish_buffer()
          @uris = find_uris("%s OFFSET %d LIMIT %d" % [QUERY_FIND_WORKS, @offset, @limit])
          @report.progress(:work, @offset, @uris.size) unless @uris.empty?
        end

        def find_uris(query)
          QueryRunner.new(query).execute(@ts).map { |r| r['uri'] }
        end
      end
    end
  end
end
