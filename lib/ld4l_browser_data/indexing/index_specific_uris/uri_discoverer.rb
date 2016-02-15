=begin rdoc
--------------------------------------------------------------------------------

Read the URIs from the selected directory, and return the ones that are of an
acceptable type.

Each line of a file may contain a URI, or it may contain a full N-triple, and
the subject URI will be used.

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module Indexing
    class IndexSpecificUris
      class UriDiscoverer
        QUERY_TYPES = <<-END
        SELECT ?type 
        WHERE {
          ?uri a ?type .
        } LIMIT 100
        END

        TYPE_WORK = 'http://bib.ld4l.org/ontology/Work'
        TYPE_INSTANCE = 'http://bib.ld4l.org/ontology/Instance'
        TYPE_PERSON = 'http://xmlns.com/foaf/0.1/Person'
        TYPE_ORGANIZATION = 'http://xmlns.com/foaf/0.1/Organization'
        def initialize(bookmark, ts, report, source_dir)
          @bookmark = bookmark
          @ts = ts
          @report = report
          @source_dir = source_dir
          @skipping_files = true
          @skipping_lines = true

          @uris = []
        end

        def each()
          if @bookmark.complete?
            @report.nothing_to_do
            return
          end
          Dir.chdir(@source_dir) do |d|
            Dir.entries(d).sort.each do |fn|
              next if skip_files(fn)
              next if invalid_file(fn)
              @report.next_file(fn)

              f = File.new(fn)
              f.each do |line|
                next if skip_lines(f)
                uri = figure_uri(line)
                type = find_type(uri)

                if type
                  yield type, uri
                else
                  @report.logit("couldn't find a type for '#{uri}'")
                end

                @report.record_uri(uri, f.lineno, fn)
                @bookmark.update(fn, f.lineno) if 0 == (f.lineno % 100)
              end
            end
          end
          @bookmark.complete
        end

        def skip_files(fn)
          if @skipping_files
            if fn >= @bookmark[:filename]
              @skipping_files = false
            end
          end
          @skipping_files
        end

        def invalid_file(fn)
          fn.start_with?('.') || File.directory?(fn)
        end

        def skip_lines(f)
          if @skipping_lines
            if f.lineno >= @bookmark[:offset]
              @skipping_lines = false
              @report.start_at_bookmark(File.basename(f.path), f.lineno)
            end
          end
          @skipping_lines
        end

        def figure_uri(line)
          if line =~ /^<?([^>\s]+)>?/
            $1
          else
            line
          end
        end

        def find_type(uri)
          QueryRunner.new(QUERY_TYPES).bind_uri('uri', uri).execute(@ts).each do |row|
            return :work if TYPE_WORK == row['type']
            return :instance if TYPE_INSTANCE == row['type']
            return :agent if TYPE_PERSON == row['type']
            return :agent if TYPE_ORGANIZATION == row['type']
          end
          return nil
        end
      end
    end
  end
end
