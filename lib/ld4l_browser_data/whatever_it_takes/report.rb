module Ld4lBrowserData
  module WhateverItTakes
    class Report
      include Utilities::ReportHelper
      def interrupted
        logit "INTERRUPTED."
      end

      def restored_files(how_many)
        logit "Restored #{how_many} files."
      end

      def submitting_task(t)
        logit "Submitting task: #{t}"
      end

      def chunk_completed(name, running_time)
        logit("#{name} completed successfully -- running time: #{running_time}.")
      end

      def chunk_failed(name, running_time, exit_code)
        logit("#{name} failed -- exit code: #{exit_code}, running time: #{running_time}")
      end

      def log_process_results(results)
        message = [" -- Process results -- "]
        message <<   'Name           pid exit_code run_time command'
        results.each do |r|
          cmd_string = r[:cmd].join(' ')
          cmd_string[20..-20] = '...' if cmd_string.size > 43
          message << '%12s %5d      %4d    %5d %s' % [r[:name], r[:pid], r[:exit_code], r[:running_time].to_i, cmd_string]
        end
        logit message.join("\n")
      end

      def log_complete
        logit "------------- Complete. ---------------"
      end
    end
  end
end
