=begin rdoc
--------------------------------------------------------------------------------

Run rapper against all eligible files in a directory tree, compiling a list of
the syntax errors in the files.

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module Ld4lIngesting
    class ScanDirectoryTree
      include Utilities::MainClassHelper

      DEFAULT_MATCHER = /.+\.(rdf|owl|nt|ttl)$/
      def initialize
        @usage_text = [
          'Usage is ld4l_scan_directory_tree \\',
          'source=<source_directory> \\',
          'report=<report_file>[~REPLACE] \\',
        ]

        @bad_files_count = 0
        @error_count = 0
        @filename_matcher = DEFAULT_MATCHER
        @input_format = 'ntriples'
      end

      def process_arguments()
        parse_arguments(ARGV)
        @source_dir = validate_input_directory(:source, "source_directory")
        @report = Report.new('ld4l_scan_directory_tree', validate_output_file(:report, "report file"))
        @report.log_header(ARGV)
      end

      def traverse_the_directory
        Dir.chdir(@source_dir) do
          Find.find('.') do |path|
            if File.file?(path) && path =~ @filename_matcher
              scan_file_and_record_errors(path)
            end
          end
        end
      end

      def scan_file_and_record_errors(path)
        `rapper -i #{@input_format} #{path} - > /dev/null 2> #{@tempfile_path}`

        error_lines = File.readlines(@tempfile_path).each.select {|l| l.index('Error')}
        unless error_lines.empty?
          @bad_files_count += 1
          @error_count += error_lines.size
          @report.log_only("Errors: \n" + error_lines.join)
        end
        @report.logit "-- found #{error_lines.size} errors in #{path}"
      end

      def report
        @report.logit ">>>>>>> bad files #{@bad_files_count}, errors #{@error_count}"
      end

      def run()
        begin
          process_arguments()
          begin
            begin
              tempfile = Tempfile.new('ld4l_scan')
              @tempfile_path = tempfile.path
              traverse_the_directory()
              report
            ensure
              tempfile.close! if tempfile
            end
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
