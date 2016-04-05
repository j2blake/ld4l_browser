=begin rdoc
--------------------------------------------------------------------------------

Start with one or more directories, separated by commas. For each file of URIs
in the directories, pull a URI at intervals, create an index page URL from it,
and see whether that index page URL returns a page or an error.

Options: what size interval, stop after max URIs tested, skip files.

Log by file, wins/losses, and a sample of failing URIs.
Log totals, how many files, how many with failures, how many without failures,
            how many URIs, how many failures, how many successes.

--------------------------------------------------------------------------------
=end
require "ld4l_browser_data/utilities/main_class_helper"

require_relative "uri_discoverer"

module Ld4lBrowserData
  module SpotCheck
    module BaseChecker
      include Utilities::MainClassHelper
      def initialize(process_name)
        @usage_text = [
          'Usage is %s \\' % process_name,
          'source=<source_dir[,...]> \\',
          'report=<report_file>[~REPLACE] \\',
          '[uri_interval=<uri_sample_rate(5000)>] \\',
          '[file_interval=<file_sample_rate(1)>] \\',
          '[filename_matcher=<file_basename_pattern(^split_)>] \\',
          '[max_tests=<maximum_number_of_texts(1000000)>] \\',
          '[progress_interval=<progress_reporting_interval(1000)>] \\',
        ]
      end

      def process_arguments()
        parse_arguments(:source, :report, :uri_interval, :file_interval, :filename_matcher, :max_tests, :progress_interval)
        @sources = validate_input_directories(:source, 'source directories')
        @uri_interval = validate_integer(key: :uri_interval, label: 'uri_sample_rate', min: 1, default: '5000')
        @file_interval = validate_integer(key: :file_interval, label: 'file_sample_rate', min: 1, default: '1')
        @filename_matcher = Regexp.compile(@args[:filename_matcher] || '^split_', nil)
        @max_tests = validate_integer(key: :max_tests, label: 'maximum_number_of_texts', min: 1, default: '1000000')
        @progress_interval = validate_integer(key: :progress_interval, label: 'progress_reporting_interval', min: 1, default: '1000')
        @report = new_report(validate_output_file(:report, "report file"), @progress_interval)
        @report.log_header
      end

      def trap_control_c
        @interrupted = false
        trap("SIGINT") do
          @interrupted = true
        end
      end

      def process_interruption
        @report.summarize(:interrupted)
      end

      def do_tests
        uri_infos = UriDiscoverer.new(@sources, @report, @uri_interval, @file_interval, @filename_matcher, @max_tests)
        uri_infos.each do |info|
          if @interrupted
            process_interruption
            raise UserInputError.new("INTERRUPTED")
          else
            new_uri_processor(info, @report).test_it
          end
        end
      end

      def run()
        begin
          process_arguments
          trap_control_c

          do_tests

          @report.summarize
        rescue UserInputError, IllegalStateError
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
