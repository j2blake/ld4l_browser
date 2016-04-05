=begin

Show a progress line after every 1000 tests.
Show a failure count and some examples for each file that contains failures.
Summarize how many tests in how many files, and how many failures in how many failing files.

=end
require "ld4l_browser_data/utilities/report_helper"

module Ld4lBrowserData
  module SpotCheck
    class IndexChecker
      class Report
        include Utilities::ReportHelper
        def initialize(main_routine, path)
          super
          @map = Hash.new{|h, k| h[k] = FileStat.new(k)}
          @count_total = 0
        end

        def success(info, response)
          @map[info[:file]].success
          record_progress(info)
        end

        def failure(info, response)
          @map[info[:file]].failure(info)
          record_progress(info)
        end

        def record_progress(info)
          @count_total += 1
          write_running_total if running_total_ready?
          write_file_failures if end_of_file?(info) && file_has_failures?
          @current_file = info[:file]
        end

        def write_running_total
          logit('ran %6d tests.' % @count_total)
        end

        def running_total_ready?
          0 == @count_total % 1000
        end

        def write_file_failures
          stats = @map[@current_file]
          logit("%4d failures (%4d successes) in %s\n    Failure examples: %s" %  [
            stats.failures,
            stats.successes,
            @current_file,
            stats.examples.map{|ex| format_failure_example(ex)}.join("\n" + ' ' * 22)
          ])
        end

        def format_failure_example(ex)
          'line %6d: %s' % [ex[:line], ex[:uri]]
        end

        def end_of_file?(info)
          @current_file && @current_file != info[:file]
        end

        def file_has_failures?
          @map[@current_file].failures > 0
        end

        def summarize(status=:normal)
          # The call to summarize is the final end-of-file
          write_file_failures if file_has_failures?

          failing_files = @map.values.inject(0){|sum, stat| stat.failures == 0 ? sum : sum + 1}
          failing_tests = @map.values.inject(0){|sum, stat| sum + stat.failures}
          logit("\nOf %d files tested, %d contain failures.\nOf %d URIs tested, %d failed." % [
            @map.size,
            failing_files,
            @count_total,
            failing_tests
          ])
        end
      end

      class FileStat
        EXAMPLE_LIMIT = 5
        attr_reader :successes
        attr_reader :failures
        attr_reader :examples
        def initialize(path)
          @path = path
          @successes = 0
          @failures = 0
          @examples = []
        end

        def success
          @successes += 1
        end

        def failure(info)
          @failures += 1
          @examples << info if @examples.size < EXAMPLE_LIMIT
        end
      end
    end
  end
end
