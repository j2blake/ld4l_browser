=begin
  Assumes than any including class will provide these instance variables:
  @source_dir -- directory where the source files are found
  @source_files -- array of paths to eligible files
  @target_dir -- directory where the created filew will be written
  @report -- report class
=end

module Ld4lBrowserData
  module AdditionalTriples
    module DistillerCore
      def find_source_file_paths(pattern)
        Dir.entries(@source_dir).select{|fn| fn =~ pattern}.map{|fn| in_source_dir(fn)}
      end

      def in_source_dir(filename)
        File.join(@source_dir, filename)
      end

      def in_target_dir(filename)
        File.join(@target_dir, filename)
      end

      def get_localname(uri)
        /[^#\/]*$/ =~ strip_angles(uri)
        $~[0]
      end

      #
      # Search all of the source_files for lines that match the pattern. Write
      # the matching lines to the out_path.
      #
      def filter(pattern, out_path)
        how_many = @source_files.size
        File.open(out_path, 'w') do |out|
          @report.start_filter(pattern, out.path, how_many)
          count = @source_files.map{ |path| filter_one_file(path, pattern, out) }.inject(:+)
          @report.end_filter(pattern, out.path, how_many, count)
        end
      end

      def filter_one_file(in_path, pattern, out)
        count = 0
        File.foreach(in_path) do |line|
          if pattern =~ line
            out.puts(line.split.map {|v| strip_quotes(strip_angles(v))}.join(' '))
            count += 1
          end
        end
        count
      end

      #
      # Join the file at in_path_1 to the file at in_path_2, using field_1 and field_2
      # as the matching criteria.
      #
      # out_fields specifies the values that are written to each line of out_path.
      # For example, [[1, 1], [1, 2], [2, 2]] says to write the 1st and 2nd fields of
      # file 1 and the 2nd field of file 2.
      #
      # Field numbers are 1-origin.
      #
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

      def strip_angles(raw)
        /^<?([^<>]*)>?$/ =~ raw
        $~[1]
      end

      def strip_quotes(raw)
        if /^"?([^"]*)"?$/ =~ raw
          $~[1]
        else
          raw
        end
      end
    end
  end
end
