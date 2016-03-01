module Ld4lBrowserData
  module WhateverItTakes
    class Indexer
      class Report
        include Utilities::ReportHelper
        
        def log_process_results(results)
          bogus "Report.log_process_results not implemented"
        end
        def log_complete
          bogus "Report.log_complete not implemented"
        end
      end
    end
  end
end
