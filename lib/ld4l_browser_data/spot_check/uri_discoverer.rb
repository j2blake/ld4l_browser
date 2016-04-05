=begin

Sample the files according to the input specs. Each return will be a hash of
:uri, :file, :line

=end
require 'find'

module Ld4lBrowserData
  module SpotCheck
    class UriDiscoverer
      def initialize(sources, report, uri_interval, file_interval, filename_matcher, max_tests)
        @sources = sources
        @report = report
        @uri_interval = uri_interval
        @file_interval = file_interval
        @max_tests = max_tests
        @filename_matcher = filename_matcher
      end

      def each
        files = FilesEnumerator.new(@sources, @filename_matcher)
        all_lines = AllLinesEnumerator.new(files)
        selected_lines = SelectedLinesEnumerator.new(@uri_interval, all_lines)
        limited_selected_lines = LimitedLinesEnumerator.new(@max_tests, selected_lines)
        limited_selected_lines.each do |info|
          yield info
        end
      end
    end

    class FilesEnumerator
      def initialize(dirs, filename_matcher)
        @dirs = dirs
        @filename_matcher = filename_matcher
      end

      def each
        @dirs.each do |d|
          Find.find(d) do |path|
            if File.file?(path) && File.basename(path) =~ @filename_matcher
              yield path
            end
          end
        end
      end
    end

    class AllLinesEnumerator
      def initialize(files)
        @files = files
      end

      def each
        @files.each do |path|
          File.open(path) do |f|
            f.each_line do |line|
              info = {uri: line.chomp, file: path, line: $.}
              yield info
            end
          end
        end
      end
    end

    class SelectedLinesEnumerator
      def initialize(interval, all_lines)
        @interval = interval
        @all_lines = all_lines
      end

      def each
        @total_lines = 0
        @all_lines.each do |info|
          if @total_lines % @interval == 0
            yield info
          end
          @total_lines += 1
        end
      end
    end

    class LimitedLinesEnumerator
      def initialize(limit, lines)
        @lines = lines
        @limit = limit
        @so_far = 0
      end

      def each
        @lines.each do |info|
          if @so_far < @limit
            yield info
          end
          @so_far += 1
        end
      end
    end
  end
end
