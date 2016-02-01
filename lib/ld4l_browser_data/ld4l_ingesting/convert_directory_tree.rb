=begin rdoc
--------------------------------------------------------------------------------

Run rapper against all eligible files in a directory tree, comverting RDF/XML to
NTriples.

If you supply a regular expression, any file whose path matches the expression
is eligible for conversion. By default, files whose names end in ".owl" or ".rdf"
are eligible.

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module Ld4lIngesting
    class ConvertDirectoryTree
      DEFAULT_MATCHER = /.+\.(rdf|owl)$/

      include Utilities::MainClassHelper
      def initialize
        @usage_text = [
          'Usage is ld4l_convert_directory_tree \\',
          'source=<source_directory> \\',
          'target=<target_directory>[~REPLACE] \\',
          'report=<report_file>[~REPLACE] \\'
        ]

        @files_count = 0
      end

      def process_arguments()
        parse_arguments(ARGV)

        @source_dir = validate_input_directory(:source, "source_directory")
        @target_dir = validate_output_directory(:target, "target_directory")
        @report = Report.new('ld4l_convert_directory_tree', validate_output_file(:report, "report file"))

        @report.log_header(ARGV)
      end

      def traverse
        Dir.chdir(@source_dir) do
          Find.find('.') do |path|
            output_path = File.expand_path(path, @output_dir)
            if File.directory?(path)
              FileUtils.mkdir_p(output_path)
            elsif File.file?(path) && path =~ DEFAULT_MATCHER
              convert_file(path, output_path)
            end
          end
        end
      end

      def convert_file(path, output_path)
        @report.logit "converting #{path}"
        `rapper #{path} - > #{output_path}.nt`
        @files_count += 1
      end

      def report
        @report.logit(">>>>>>> converted #{@files_count} files.")
      end

      def run()
        begin
          process_arguments
          begin
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
