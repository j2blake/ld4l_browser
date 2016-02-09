=begin rdoc
--------------------------------------------------------------------------------

Multiply existing N-Triples files to produce a full-sized synthetic data set.

Create copies of the original files, but each copy uses distinct URIs for the
local data. These URIs are created by prefixing the original localname with a
code that is also added to the filename.

For example, if a file named bfInstance.nt contains this line:
    bfInstance.nt
        <http://draft.ld4l.org/cornell/n12345> a <http://bib.ld4l.org/ontology/Work>
then the two generated copies would be
    bfInstance--a.nt
        <http://draft.ld4l.org/cornell/a--n12345> a <http://bib.ld4l.org/ontology/Work>
    bfInstance--b.nt
        <http://draft.ld4l.org/cornell/b--n12345> a <http://bib.ld4l.org/ontology/Work>

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module Scalability
    class SynthesizeDataCopies
      include Utilities::MainClassHelper
      def initialize
        @usage_text = [
          'Usage is ld4l_synthesize_data_copies \\',
          'source=<source_directory> \\',
          'target=<target_directory>[~REPLACE] \\',
          'copies=<number_of_copies> \\',
          'report=<report_file>[~REPLACE] \\',
          '[IGNORE_SURPRISES]'
        ]
      end

      def process_arguments()
        parse_arguments(:source, :target, :copies, :report, :IGNORE_SURPRISES)
        @source_dir = validate_input_directory(:source, "source_directory")
        @num_copies = validate_integer(:key => :copies, :label => "number_of_copies", :min => 1, :max => 26)
        @target_dir = validate_output_directory(:target, "target_directory")
        @report = Report.new('ld4l_synthesize_data_copies', validate_output_file(:report, "report file"))
        @report.log_header
      end

      def prepare_target_directory()
        FileUtils.rm_r(@target_dir) if Dir.exist?(@target_dir)
        Dir.mkdir(@target_dir)
      end

      def check_for_surprises
        check_site_consistency(@args[:IGNORE_SURPRISES], {
          'Source directory' => @source_dir,
          'Target directory' => @target_dir,
          'Report path' => @report
        })
      end
      def make_copies
        @prefix = 'a'
        @num_copies.times do
          process_directory
          @prefix.succ!
        end
      end

      def process_directory
        Dir.foreach(@source_dir) do |fn|
          next if fn.start_with?('.')
          next unless fn.end_with?('.nt')
          process_file(fn)
        end
      end

      def process_file(fn)
        @report.logit("Creating #{output_file(fn)}")
        Dir.chdir(@source_dir) do
          File.open(output_file(fn), 'w') do |out|
            File.foreach(fn) do |line|
              out << process_line(line)
            end
          end
        end
      end

      def process_line(line)
        line.gsub(%r{<http://draft.ld4l.org/([^/]+)/([^/]+)>}, '<http://draft.ld4l.org/\1/%s--\2>' % @prefix)
      end

      def report
        @report.logit('Completed %s copies.' % @num_copies)
      end

      def output_file(fn)
        File.join(@target_dir, fn.gsub(/.nt$/, '--%s.nt' % @prefix))
      end

      def run()
        begin
          process_arguments
          check_for_surprises
          begin
            prepare_target_directory
            make_copies
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
