module Ld4lBrowserData
  module AdditionalTriples
    class Report
      include ReportHelper
      
      def start_method(name)
        logit("Starting #{name}")
      end
      
      def end_method_with_count(name, count)
        logit("Finished #{name}, count=#{count}")
      end
      
      def start_filter(in_path, out_path)
        in_basename = File.basename(in_path)
        out_basename = File.basename(out_path)
        logit("Filtering %s to %s" % [in_basename, out_basename])
      end
      
    def end_filter(in_path, out_path, count)
        in_basename = File.basename(in_path)
        out_basename = File.basename(out_path)
        logit("Filtered %s to %s, count = %d" % [in_basename, out_basename, count])
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
    end
  end
end