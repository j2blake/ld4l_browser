=begin
--------------------------------------------------------------------------------

Write the report to a file, and to the console.

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module GenerateLod
    class LinkedDataCreator
      class Report
        class NamedSize
          attr_reader :name
          attr_reader :size
          def initialize(name, size)
            @name = name
            @size = size
          end

          def update(name, size)
            @name = name
            @size = size
          end

          def to_s
            "%5d (%s)" % [@size, @name]
          end
        end

        class Largest < NamedSize
          def update(name, size)
            if @size < size
              super
            end
          end
        end

        class Smallest < NamedSize
          def update(name, size)
            if @size < 0 || @size > size
              super
            end
          end
        end

        class UriCounter
          attr_reader :good
          attr_reader :bad
          attr_reader :failed
          def initialize
            @good = 0
            @bad = 0
            @failed = 0
          end

          def another_good
            @good += 1
          end

          def another_bad
            @bad += 1
          end

          def another_failed
            @failed += 1
          end

          def any_good?
            @good > 0
          end

          def count
            @good + @bad + @failed
          end

          def to_s
            "Valid URIs: %d, Invalid URIs %d, Failed URIs %d" % [@good, @bad, @failed]
          end

        end

        class GraphCounter
          attr_reader :total_triples
          attr_reader :largest_graph
          attr_reader :smallest_graph
          attr_reader :how_many
          def initialize
            @how_many = 0
            @total_triples = 0
            @largest_graph = Largest.new('NONE', -1)
            @smallest_graph = Smallest.new('NONE', -1)
          end

          def add(uri, graph)
            @how_many += 1
            @total_triples += graph.count
            @largest_graph.update(uri, graph.count)
            @smallest_graph.update(uri, graph.count)
          end

          def to_s
            if @total_triples == 0
              " Triples: 0 "
            else
              " Triples: %d \nAverage graph size: %d, \n   smallest: %s, \n   largest:  %s" % [
                @total_triples,
                @total_triples / @how_many,
                @smallest_graph,
                @largest_graph
              ]
            end
          end
        end

        class ContentCounter
          def add(uri, content)
          end
        end

        include Utilities::ReportHelper

        def initialize(main_routine, path)
          super(main_routine, path)

          @uri_counter = UriCounter.new
          @graph_counter = GraphCounter.new
          @content_counter = ContentCounter.new

          @current_filename = 'NO FILE'
          @current_line_number = 0
        end

        def log_bookmark(bookmark)
          if bookmark.filename.empty? && !bookmark.complete?
            logit "No bookmark: starting from the beginning."
          elsif bookmark.complete?
            logit "Bookmark says we already completed this process."
          else
            logit "Starting from the bookmark: filename=%s, offset=%d" % [bookmark.filename, bookmark.offset]
          end
        end

        def next_file(filename)
          logit("Opening file: " + filename)
          @current_filename = filename
          @current_line_number = 0
        end

        def start_at_bookmark(bookmark)
          logit("Starting at line #{bookmark.offset} in #{bookmark.filename}")
        end

        def record_uri(uri, line_number, filename)
          @current_line_number = line_number
        end

        def wrote_it(uri, graph, content)
          @uri_counter.another_good
          @graph_counter.add(uri, graph)
          @content_counter.add(uri, content)
          announce_progress
        end

        def bad_uri(uri)
          @uri_counter.another_bad
          announce_progress
        end

        def uri_failed(uri, e)
          @uri_counter.another_failed
          logit("URI failed: '#{uri}' #{e}")
          announce_progress
        end

        def announce_progress
          logit("Processed #{@uri_counter.count} URIs.") if 0 == @uri_counter.count % 1000
        end

        def summarize(bookmark, status)
          first = bookmark.start[:filename]
          first = 'FIRST' if first.empty?
          last = bookmark.filename
          last = 'LAST' if last.empty?
          how_many = @uri_counter.count
          if status == :complete
            logit("Generated for URIs from %s to %s: processed %d URIs." % [first, last, how_many])
          elsif status == :interrupted
            logit("Interrupted in file %s -- started at %s: processed %d URIs." % [last, first, how_many])
          else
            logit("Error in file %s -- started at %s: processed %d URIs.  \n%s  \n%s" % [last, first, how_many, $!.inspect, $!.backtrace.join("\n")])
          end
        end

        def stats()
          message = @uri_counter.to_s
          message << "\n" << @graph_counter.to_s
          logit(message)
        end
      end
    end
  end
end
