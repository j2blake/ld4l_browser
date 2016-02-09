=begin rdoc
--------------------------------------------------------------------------------

Traverse the input directory and its subdirectories, copying all '.nt' files
into the output directory, filtering out all triples with known syntax errors.

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module Ld4lIngesting
    class FilterNtriples
      include Utilities::MainClassHelper

      INVALID_URI_CHARACTERS = /[^\w\/?:;@&=+$,-.!~*()'%#\[\]]/
      INVALID_PREFIX_CHARACTERS= /[^\w.-:]/
      def initialize
        @usage_text = [
          'Usage is ld4l_filter_ntriples \\',
          'source=<source_directory> \\',
          'target=<target_directory>[~REPLACE] \\',
          'report=<report_file>[~REPLACE] \\'
        ]

        @blank_lines_count = 0
        @bad_triples_count = 0
        @good_triples_count = 0
        @bad_files_count = 0
        @files_count = 0
        @error_count = 0
      end

      def process_arguments()
        parse_arguments(:source, :target, :report)
        @source_dir = validate_input_directory(:source, "source_directory")
        @target_dir = validate_output_directory(:target, "target_directory")
        @report = Report.new('ld4l_filter_ntriples', validate_output_file(:report, "report file"))
        @report.log_header
      end

      def prepare_target_directory()
        FileUtils.rm_r(@target_dir) if Dir.exist?(@target_dir)
        Dir.mkdir(@target_dir)
      end

      def traverse
        Dir.chdir(@source_dir) do
          Find.find('.') do |path|
            output_path = File.expand_path(path, @target_dir)
            if File.directory?(path)
              FileUtils.mkdir_p(output_path)
            elsif File.file?(path) && path.end_with?('.nt')
              filter_file(path, output_path)
            end
          end
        end
      end

      def filter_file(in_path, out_path)
        blank = 0
        total = 0
        good = 0
        errors = 0

        `rapper -i 'ntriples' #{in_path} - > #{out_path} 2> #{@tempfile_path}`

        error_lines = File.readlines(@tempfile_path).each.select {|l| l.index('Error')}
        unless error_lines.empty?
          @bad_files_count += 1
          @report.log_only("Errors:\n" + error_lines.join)
          errors = error_lines.size
        end

        File.foreach(in_path) do |line|
          total += 1
          if line.strip.empty?
            blank += 1
          end
        end

        File.foreach(out_path) do |line|
          good += 1
        end

        bad = total - blank - good

        @files_count += 1
        @good_triples_count += good
        @blank_lines_count += blank
        @bad_triples_count += bad
        @error_count += errors

        @report.logit("Found #{good} good triples, #{bad} bad triples (#{errors} errors), and #{blank} blank lines in #{in_path}")
      end

      def report()
        @report.logit "Processed #{@good_triples_count} good triples in #{@files_count} files."
        @report.logit "Found #{@bad_triples_count} bad triples (#{@error_count} errors) and #{@blank_lines_count} blank lines in #{@bad_files_count} files."
      end

      def run()
        begin
          process_arguments()
          begin
            prepare_target_directory

            tempfile = Tempfile.new('ld4l_scan')
            @tempfile_path = tempfile.path

            traverse
            report
          ensure
            tempfile.close! if tempfile
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
