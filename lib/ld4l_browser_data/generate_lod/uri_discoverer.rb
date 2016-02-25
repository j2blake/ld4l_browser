=begin
--------------------------------------------------------------------------------

Repeatedly get bunches of URIs from the list files. Dispense them one at a time.

As each new file is opened, persist the bookmark.

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module GenerateLod
    class UriDiscoverer
      def initialize(ts, source_files, bookmark, report)
        @ts = ts
        @source_files = source_files
        @bookmark = bookmark
        @report = report
        @skipping_files = true
        @skipping_lines = true
      end

      def each()
        if @bookmark.complete?
          @report.nothing_to_do
          return
        end
        @source_files.each do |f|
          fn = File.basename(f.path)
          next if skip_files(fn)
          next if invalid_file(fn)
          @report.next_file(fn)

          f.each do |line|
            next if skip_lines(f)
            uri = line.split(' ')[0]
            yield uri
            @report.record_uri(uri, f.lineno, fn)
            @bookmark.update(fn, f.lineno) if 0 == (f.lineno % 100)
          end
        end
        @bookmark.complete
      end

      def skip_files(fn)
        if @skipping_files
          if fn >= @bookmark.filename
            @skipping_files = false
          end
        end
        @skipping_files
      end

      def skip_lines(f)
        if @skipping_lines
          if f.lineno >= @bookmark.offset
            @skipping_lines = false
            @bookmark.update(File.basename(f.path), f.lineno)
            @report.start_at_bookmark(@bookmark)
          end
        end
        @skipping_lines
      end

      def invalid_file(fn)
        fn.start_with?('.') || File.directory?(fn)
      end
    end
  end
end
