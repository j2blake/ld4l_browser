module Ld4lBrowserData
  module WhateverItTakes
    class Generator
      class Report
        include Utilities::ReportHelper
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
          bogus "Complete."
        end
      end
    end
  end
end
