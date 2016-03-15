module Ld4lBrowserData
  module AdditionalTriples
    class Report
      include Utilities::ReportHelper
      def start_method(name)
        logit("Starting #{name}")
      end

      def end_method_with_count(name, count)
        logit("Finished #{name}, count=#{count}")
      end

#      @report.start_filter(pattern, out.path, how_many)
#      File.open(out_path, 'w') do |out|
#        count += @source_files.each{ |path| filter_one_file(path, pattern, out) }
#      end
#      @report.end_filter(pattern, out.path, how_many, count)

      def start_filter(pattern, out_path, how_many_files)
        out_basename = File.basename(out_path)
        logit("Filtering %d files to %s by %s" % [how_many_files, out_basename, pattern.inspect])
      end

      def end_filter(pattern, out_path, how_many_files, count)
        out_basename = File.basename(out_path)
        logit("Filtered  %d files to %s by %s, count=%d" % [how_many_files, out_basename, pattern.inspect, count])
      end

      def start_join(in_path_1, in_path_2, out_path)
        in1_name = File.basename(in_path_1)
        in2_name = File.basename(in_path_2)
        out_name = File.basename(out_path)
        logit("Joining %s and %s to %s" % [in1_name, in2_name, out_name])
      end

      def end_join(in_path_1, in_path_2, out_path, count)
        in1_name = File.basename(in_path_1)
        in2_name = File.basename(in_path_2)
        out_name = File.basename(out_path)
        logit("Joined %s and %s to %s, count = %d" % [in1_name, in2_name, out_name, count])
      end
      def start_concat(in_path_1, in_path_2, out_path)
        in1_name = File.basename(in_path_1)
        in2_name = File.basename(in_path_2)
        out_name = File.basename(out_path)
        logit("Concatenate %s and %s to %s" % [in1_name, in2_name, out_name])
      end

      def end_concat(in_path_1, in_path_2, out_path, count)
        in1_name = File.basename(in_path_1)
        in2_name = File.basename(in_path_2)
        out_name = File.basename(out_path)
        logit("Concatenated %s and %s to %s, count = %d" % [in1_name, in2_name, out_name, count])
      end
    end
  end
end