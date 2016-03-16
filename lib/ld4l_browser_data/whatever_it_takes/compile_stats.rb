=begin rdoc
--------------------------------------------------------------------------------

One of the WIT processes has generated a whole slew of JSON stats files. Merge
them together and display the result in a chosen format.

--------------------------------------------------------------------------------

>>>>>>>> TO DO:

    indexing
      show the whole thing.
      for doc_counts and occurences, try: found on 99 Agents, up to 123 per Agent. <<<< CHANGE TO STATS to get max

--------------------------------------------------------------------------------
=end
require 'json'

require_relative 'compile_stats/formats'
require_relative 'compile_stats/json_stats_accumulator'
require_relative 'compile_stats/report'

module Ld4lBrowserData
  module WhateverItTakes
    class CompileStats
      include Utilities::MainClassHelper

      FORMATS = Formats.keys

      def initialize
        @usage_text = [
          'Usage is wit_compile_stats \\',
          'source=<source_directory> \\',
          'report=<report_file>[~REPLACE] \\',
          "[output_format=<#{FORMATS.join('|')}>] \\",
        ]
      end

      def process_arguments()
        parse_arguments(:source, :report, :output_format)
        @source = validate_input_directory(:source, "source directory")
        @report = Report.new('wit_compile_stats', validate_output_file(:report, "report file"))
        @output_format = validate_output_format
        @report.log_header
      end

      def validate_output_format
        f = @args[:output_format]
        if f
          format = f.to_sym
        else
          format = FORMATS[0]
        end
        user_input_error("Valid formats are #{FORMATS.join(', ')}") unless FORMATS.include?(format)
        format
      end

      def gather_stats
        @accumulator = JsonStatsAccumulator.new(max_array_size: 5)
        Dir.chdir(@source) do
          Dir.entries('.').each do |fn|
            if fn.end_with?('.js')
              File.open(fn) do |f|
                @accumulator << JSON.load(f)
              end
            end
          end
        end
        raise IllegalStateError.new("No stats files in #{@source}.") if @accumulator.empty?
      end

      def report
        @report.write_formatted_summary(@output_format, @accumulator.summary)
      end

      def run
        begin
          process_arguments
          gather_stats
          report
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
