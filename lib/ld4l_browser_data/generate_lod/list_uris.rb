=begin rdoc
--------------------------------------------------------------------------------

Generate a group of files that contain all of the URIs that we want to serve as
LOD.

Start with a directory-tree of N-Triples files. Do each institution separately.
Assume that there are no URIs in common.

First: process each file, trimming each line to just the subject URI. Remove
any non-local URIs, sort and remove duplicates.

Next: do a successive operation merging batches of files until only one large
file remains.

Finally, split the big file into smaller segments.

--------------------------------------------------------------------------------

Usage: <process_name> <source_dir> <output_dir> [RESTART] <report_file> [REPLACE] [PARTITION <ways>]

The calling routine passes 'ld4l_list_uris' or other name to the
constructor, along with a string version of a regexp, for awk to use when
selecting triples.

--------------------------------------------------------------------------------
=end
require_relative 'list_uris/report'

module Ld4lBrowserData
  module  GenerateLod
    class ListUris
      include Utilities::MainClassHelper
      def initialize(process_name, triple_matcher)
        @usage_text = "Usage: #{process_name} <source_dir> <output_dir> [OVERWRITE] <report_file> [REPLACE] [PARTITION <ways>]"
        @process_name = process_name
        @triple_matcher = triple_matcher

        @usage_text = [
          "Usage is #{@process_name} \\",
          'source=<source_directory> \\',
          'target=<target_directory>[~REPLACE] \\',
          'report=<report_file>[~REPLACE] \\',
          '[partition=<num_partitions>] \\',
          '[split_size=<num_lines>] \\',
          '[IGNORE_SITE_SURPRISES] \\',
        ]

        @uri_prefix = 'http://draft.ld4l.org/'
      end

      def process_arguments()
        parse_arguments(:source, :target, :report, :partition, :split_size, :IGNORE_SITE_SURPRISES)
        @source_dir = validate_input_directory(:source, "source_directory")
        @target_dir = validate_output_directory(:target, "target_directory")
        @report = Report.new(@process_name, validate_output_file(:report, "report file"))
        @partitions = validate_integer(:key => :partition, :label => 'number of partitions', :min => 1, :default => '1')
        @split_size = validate_integer(:key => :split_size, :label => 'lines in result files', :min => 1000, :default => '100000')
        @ignore_surprises = @args[:IGNORE_SITE_SURPRISES]
        @report.log_header
      end

      def check_for_surprises
        check_site_consistency(@ignore_surprises, {
          'Source directory' => @source_dir,
          'Target directory' => @target_dir,
          'Report path' => @report
        })
      end

      MERGE_BATCH_SIZE = 40

      def prepare_target
        FileUtils.rm_r(@target_dir) if Dir.exist?(@target_dir)
        Dir.mkdir(@target_dir)
      end

      def first_pass
        @report.first_pass_start

        @first_pass_dir = File.join(@target_dir, 'first_pass')
        Dir.mkdir(@first_pass_dir) unless File.exist?(@first_pass_dir)

        Find.find(@source_dir) do |path|
          if File.file?(path) && path.end_with?('.nt') && !path.start_with?('.')
            process_first_pass_file(path)
          end
        end
        @report.first_pass_stop
      end

      def process_first_pass_file(path)
        new_filename = path[@source_dir.size..-1].gsub('/', '__')
        output_file = File.join(@first_pass_dir, new_filename)
        `awk '#{@triple_matcher} { gsub(/[<>]/, "", $1); print $1}' #{path} | sort -u > #{output_file}`
        @report.first_pass_file(new_filename)
      end

      def merge_passes
        dir_index = 1
        source = @first_pass_dir
        target = merge_target_dir(dir_index)
        loop do
          how_many_batches = merge_pass(source, target)
          break if how_many_batches <= 1
          source = target
          dir_index += 1
          target = merge_target_dir(dir_index)
        end
        @last_merge_file = merge_target_file(target, 1)
        @report.merge_passes_summary(@last_merge_file[@target_dir.size..-1])
      end

      def merge_pass(source, target)
        @report.merge_pass_start(source, target)
        batch_index = 0
        Dir.mkdir(target) unless File.exist?(target)
        Dir.chdir(source) do |d|
          Dir.entries(source).reject {|fn| fn.start_with?('.')}.each_slice(MERGE_BATCH_SIZE) do |slice|
            batch_index += 1
            target_file = merge_target_file(target, batch_index)
            `sort -m -u #{slice.join(' ')} > #{target_file}`
          end
        end
        @report.merge_pass_stop(batch_index)
        batch_index
      end

      def merge_target_dir(index)
        File.join(@target_dir, "merge_#{index}")
      end

      def merge_target_file(dir, index)
        File.join(dir, "merge_output_#{index}")
      end

      def split
        @split_dir = File.join(@target_dir, 'splits')
        Dir.mkdir(@split_dir) unless File.exist?(@split_dir)
        Dir.chdir(@split_dir) do
          `split -a4 -l #{@split_size} #{@last_merge_file} split_`
        end
        @report.logit("Split pass complete")
      end

      def partition
        make_partition_directories
        move_to_partitions
        remove_split_directory
        @report.partition_complete(@partition_directories)
      end

      def make_partition_directories()
        @partition_directories = []
        1.upto(@partitions) do |i|
          dir = File.join(@target_dir, "partition_#{i}")
          Dir.mkdir(dir)
          @partition_directories << dir
        end
      end

      def move_to_partitions()
        count = 0
        Dir.chdir(@split_dir) do
          Dir.foreach('.') do |fn|
            next unless fn.start_with?('split_')
            `mv #{fn} #{@partition_directories[count % @partitions]}`
            count += 1
          end
        end
      end

      def remove_split_directory
        Dir.delete(@split_dir)
      end

      def run
        begin
          process_arguments
          check_for_surprises
          prepare_target
          first_pass
          merge_passes
          split
          partition
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