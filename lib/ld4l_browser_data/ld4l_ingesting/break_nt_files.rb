=begin
--------------------------------------------------------------------------------

As with convert_directory, keep the subdirectory structure and corresponding fileames.
When breaking, append to the filename __001, __002, etc.
If the file is small enough, keep the original filename and just copy.

Stupid approach:
  Read a line at a time. Decide whether the line contains one or more blank nodes.
  If it contains a blank node, write it to the blank node file.
    Otherwise, write to one of the regular files.
  The problem with this is that as many as 30% of the lines contain blank nodes.

Two-pass approach:
  First pass:
    pass through, creating a map of the first and last mention of each blank node.
    record the number of lines in the file.
  Find break points:
    start at the desired break point (max-triples past the previous break point)
    search the map to see if the break poiint is eligible.
    if ineligible, try the next smaller.

    if no eligible break point is found, begin incrementing and checking.
      if found, issue a warning and break it there.
  Second pass:
    read through the file, breaking as determined.

--------------------------------------------------------------------------------

Usage: ld4l_break_nt_files <input_directory> <output_directory> [OVERWRITE] <report_file> [REPLACE] <max_triples>

--------------------------------------------------------------------------------
=end
require_relative 'break_nt_files/breakpoint_finder'
require_relative 'break_nt_files/file_breaker'
require_relative 'report'

module Ld4lBrowserData
  module Ld4lIngesting
    class BreakNtFiles
      include Utilities::MainClassHelper

      FILENAME_MATCHER = /^.+\.nt$/
      
      def initialize
        @usage_text = [
          'Usage is ld4l_break_nt_files \\',
          'source=<source_directory> \\',
          'target=<target_directory>[~REPLACE] \\',
          'report=<report_file>[~REPLACE] \\',
          'max_triples=<max_triples \\'
        ]
      end

      def process_arguments()
        parse_arguments(ARGV)
        @source_dir = validate_input_directory(:source, "source_directory")
        @target_dir = validate_output_directory(:target, "target_directory")
        @report = Report.new('ld4l_break_nt_files', validate_output_file(:report, "report file"))
        @max_triples = validate_integer(:key => :max_triples, :label => "max_triples", :min => 100)
        @report.log_header(ARGV)

        @files_count = 0
        @broken_count = 0
      end

      def prepare_target_directory()
        FileUtils.rm_r(@target_dir) if Dir.exist?(@target_dir)
        Dir.mkdir(@target_dir)
      end

      def traverse
        Dir.chdir(@source_dir) do
          Find.find('.') do |path|
            @input_path = File.expand_path(path, @source_dir)
            @output_path = File.expand_path(path, @target_dir)
            if File.directory?(@input_path)
              FileUtils.mkdir_p(@output_path)
            elsif File.file?(@input_path) && @input_path =~ FILENAME_MATCHER
              @files_count += 1
              process_file()
            end
          end
        end
      end

      def process_file()
        breakpoints, lines, files = find_breakpoints
        break_it(breakpoints)
        @broken_count += files
        @report.logit "Broke #{@input_path} (#{lines} lines) into #{files} files"
      end

      def find_breakpoints()
        finder = BreakpointFinder.new(@input_path, @max_triples)
        breakpoints = finder.find
        [breakpoints, finder.line_count, breakpoints.size]
      end

      def break_it(breakpoints)
        FileBreaker.new(@input_path, @output_path, breakpoints).break
      end

      def report
        @report.logit ">>>>>>> #{@files_count} files became #{@broken_count} files."
      end

      def run()
        begin
          process_arguments

          begin
            prepare_target_directory
            traverse
            report
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