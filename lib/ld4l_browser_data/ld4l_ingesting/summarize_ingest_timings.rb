=begin rdoc
--------------------------------------------------------------------------------

Summarize the ingest times. For each 100 files (or 500 or 1000), figure the
average ingest time.

Output looks like this:
2016-02-06 17:59:46 ld4l_summarize_ingest_timings source=new_ingest.txt group=2 report=ingest_summary.txt
2016-02-06 17:59:46 "Files", "Average time"
2016-02-06 17:59:46 "1-100", 14.2
2016-02-06 17:59:46 "101-200", 15.3
  ...

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module Ld4lIngesting
    class SummarizeIngestTimings
      include Utilities::MainClassHelper
      def initialize
        @usage_text = [
          'Usage is ld4l_summarize_ingest_timings \\',
          'source=<ingest_report_file> \\',
          'group=<group_size> \\',
          'report=<report_file>[~REPLACE] \\',
        ]
      end

      def process_arguments()
        parse_arguments(ARGV)
        @source_file = validate_input_file(:source, "ingest_report_file")
        @group_size = validate_integer(:key => :group, :label => "group_size", :min => 0)
        @report = Report.new('ld4l_summarize_ingest_timings', validate_output_file(:report, "report_file"))
        @report.log_header(ARGV)
      end

      def build_table()
        @table = []
        File.foreach(@source_file).select {|l| l =~ /Ingested/}.each_slice(@group_size) do |slice|
          total_time = 0.0
          slice.each_with_index do |line, i|
            begin
              if line =~ /,\s*([\d.]+)$/
                total_time += $1.to_f
              else
                puts "Invalid format, line %d: '%s'" % [line_number(i), line]
              end
            rescue
              puts "Invalid time value, line %d: '%s'" % [line_number(i), $1]
            end
          end
          @table << [line_number(0), slice.size, total_time]
        end
      end

      def line_number(i)
        @table.size * @group_size + i + 1
      end

      def write_table()
        @report.logit '"Files", "Average time"'
        @table.each do |row|
          @report.logit '"%d-%d", %.2f' % [row[0], row[0] + row[1] - 1, row[2] / row[1]]
        end
      end

      def run()
        begin
          process_arguments()

          begin
            build_table
            write_table
          ensure
            @report.close if @report
          end
        rescue UserInputError
          puts
          puts "ERROR: #{$!}"
          puts
        end
      end
    end
  end
end
