=begin
--------------------------------------------------------------------------------

Repeatedly get bunches of URIs for Agents, Instances, and Works. Dispense them
one at a time.

The query should return the uris in ?uri, and should not contain an OFFSET or
LIMIT, since they will be added here.

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module Indexing
    class BuildSolrIndex
      class UriDiscoverer
        include Enumerable
        def initialize(bookmark, ts, report, types, limit, bindings = {})
          @bookmark = bookmark
          @ts = ts
          @report = report
          @types = types
          @limit = limit
          @bindings = bindings
          @uris = []
        end

        def each()
          if @bookmark.complete?
            @report.nothing_to_do
            return
          end

          while true
            replenish_buffer if @uris.empty?
            advance_to_next_type if @uris.empty?
            if @uris.empty?
              @bookmark.complete
              return
            end

            type_id = @types[type_index][:id]
            yield type_id, @uris.shift
            @bookmark.increment
          end
        end

        def advance_to_next_type()
          if type_index < @types.size - 1
            @bookmark.next_type
            replenish_buffer
          end
        end

        def replenish_buffer()
          @uris = find_uris("%s OFFSET %d LIMIT %d" % [@types[type_index][:query], offset, @limit])
          @report.progress(@types[type_index][:id], offset, @uris.size) unless @uris.empty?
        end

        def find_uris(query)
          q = QueryRunner.new(query)
          @bindings.each_pair do |k, v|
            q.bind_uri(k, v)
          end
          q.execute(@ts).map { |r| r['uri'] }
        end

        def offset
          @bookmark[:offset]
        end

        def type_index
          @bookmark[:type_index]
        end
      end
    end
  end
end
