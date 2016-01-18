=begin
--------------------------------------------------------------------------------

Create a distillation of this site that can be used to create additional triples.

1) instance_to_worldcat.txt will be used to link instances across sites.
2) work_to_workID.txt will be used to link works across sites, and also to
   generate WorkID triples.

--------------------------------------------------------------------------------

Usage: ld4l_distill_site source=<source_directory> target=<target_directory>, concordance=<concordance_file>, report=<report_file>, [REPLACE_REPORT], [OVERWRITE_TARGET]

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module AdditionalTriples
    class SiteDistiller
      include MainClassHelper
      def initialize
        @usage_text = [
          'Usage is ld4l_distill_site \\',
          'source=<source_directory> \\',
          'target=<target_directory>[~REPLACE] \\',
          'concordance=<concordance_file> \\',
          'report=<report_file>[~REPLACE] \\'
        ]
      end

      def process_arguments()
        parse_arguments(ARGV)

        @source_dir = validate_input_directory(:source, "source_directory")
        @target_dir = validate_output_directory(:target, "target_directory")
        @concordance = validate_input_file(:concordance, "concordance file")
        @report = Report.new('ld4l_distill_site', validate_output_file(:report, "report file"))

        @bf_instance = in_source_dir('bfInstance.nt')
        @new_assertions = in_source_dir('newAssertions.nt')
        @work_to_instance = in_target_dir('work_to_instance.txt')
        @instance_to_worldcat = in_target_dir('instance_to_worldcat.txt')
        @instance_to_identifiers = in_target_dir('instance_to_identifier.txt')
        @oclc_identifiers = in_target_dir('oclc_identifiers.txt')
        @identifier_to_value = in_target_dir('identifier_to_value.txt')
        @instance_to_oclc = in_target_dir('instance_to_oclc.txt')
        @the_hard_way = in_target_dir('instance_to_worldcat_the_hard_way.txt')
        @all_instance_to_worldcat = in_target_dir('instance_to_worldcat_all.txt')
        @work_instance_worldcat = in_target_dir('work_to_instance_to_worldcat.txt')
        @work_to_work_id = in_target_dir('work_to_workID.txt')

        @report.log_header(ARGV)
      end

      def create_work_to_instance()
        @report.start_method("create_work_to_instance")
        pattern = /http:\/\/bib\.ld4l\.org\/ontology\/isInstanceOf/
        count = 0
        File.open(@work_to_instance, 'w') do |out|
          File.foreach(@bf_instance) do |line|
            if pattern =~ line
              fields = line.split
              out.puts(strip_angles(fields[2]) + ' ' + strip_angles(fields[0]))
              count += 1
            end
          end
        end
        @report.end_method_with_count("create_work_to_instance", count)
      end

      def create_instance_to_worldcat()
        @report.start_method("create_instance_to_worldcat")
        pattern = /http:\/\/www\.w3\.org\/2002\/07\/owl#sameAs.*http:\/\/www\.worldcat\.org\/oclc/
        count = 0
        File.open(@instance_to_worldcat, 'w') do |out|
          File.foreach(@new_assertions) do |line|
            if pattern =~ line
              fields = line.split
              out.puts(strip_angles(fields[0]) + " " + get_localname(fields[2]))
              count += 1
            end
          end
        end
        @report.end_method_with_count("create_instance_to_worldcat", count)
      end

      def create_additional_worldcat_ids
        filter(@bf_instance, /identifiedBy/, @instance_to_identifiers)
        filter(@bf_instance, /OclcIdentifier/, @oclc_identifiers)
        filter(@bf_instance, /22-rdf-syntax-ns#value/, @identifier_to_value)

        join(@instance_to_identifiers, 3, @oclc_identifiers, 1, @instance_to_oclc, [[1, 1], [1,3]])
        join(@instance_to_oclc, 2, @identifier_to_value, 1, @the_hard_way, [[1, 1], [2, 3]])

        concat(@instance_to_worldcat, @the_hard_way, @all_instance_to_worldcat)
      end

      def create_work_to_work_ids()
        join(@work_to_instance, 2, @all_instance_to_worldcat, 1, @work_instance_worldcat, [[1, 1], [1, 2], [2, 2]])
        join(@work_instance_worldcat, 3, @concordance, 1, @work_to_work_id, [[1, 1], [2, 2]])
      end

      def in_source_dir(filename)
        File.join(@source_dir, filename)
      end

      def in_target_dir(filename)
        File.join(@target_dir, filename)
      end

      def strip_angles(raw)
        /^<?([^<>]*)>?$/ =~ raw
        $~[1]
      end

      def get_localname(uri)
        /[^#\/]*$/ =~ strip_angles(uri)
        $~[0]
      end

      def filter(in_path, pattern, out_path)
        @report.start_filter(in_path, out_path)
        count = 0
        File.open(out_path, 'w') do |out|
          File.foreach(in_path) do |line|
            if pattern =~ line
              out.puts(line)
              count += 1
            end
          end
        end
        @report.end_filter(in_path, out_path, count)
      end

      def join(in_path_1, field_1, in_path_2, field_2, out_path, out_fields)
        @report.start_join(in_path_1, in_path_2, out_path)
        key_1_col = field_1 - 1
        key_2_col = field_2 - 1
        out_cols = out_fields.map {|field| field.map {|f| f - 1}}

        map = {}
        File.foreach(in_path_1) do |line|
          fields = line.split
          map[fields[key_1_col]] = fields
        end

        count = 0
        File.open(out_path, 'w') do |out|
          File.foreach(in_path_2) do |line|
            fields_2 = line.split
            fields_1 = map[fields_2[key_2_col]]
            if fields_1
              out.puts out_cols.map {|f| [fields_1, fields_2][f[0]][f[1]] }.join(' ')
              count += 1
            end
          end
        end
        @report.end_join(in_path_1, in_path_2, out_path, count)
      end

      def concat(in_path_1, in_path_2, out_path)
        @report.start_concat(in_path_1, in_path_2, out_path)
        count = 0
        File.open(out_path, 'w') do |out|
          File.foreach(in_path_1) do |line| out.puts(line)
            count += 1
          end
          File.foreach(in_path_2) do |line| out.puts(line)
            count += 1
          end
        end
        @report.end_concat(in_path_1, in_path_2, out_path, count)
      end

      def run
        begin
          process_arguments
          create_work_to_instance
          create_instance_to_worldcat
          create_additional_worldcat_ids
          create_work_to_work_ids
        rescue UserInputError, IllegalStateError
          puts
          puts "ERROR: #{$!}"
          puts
        ensure
          @report.close if @report
        end
      end
    end
  end
end
