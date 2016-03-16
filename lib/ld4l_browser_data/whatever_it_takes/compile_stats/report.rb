module Ld4lBrowserData
  module WhateverItTakes
    class CompileStats
      class Report
        include Utilities::ReportHelper
        def write_formatted_summary(format, summary)
          logit "--- Summarized statistics ---\n%s" % [Formats.formatter(format).format(summary)]
        end
      end
    end
  end
end
