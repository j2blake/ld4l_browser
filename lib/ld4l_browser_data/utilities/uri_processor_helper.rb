module Ld4lBrowserData
  module Utilities
    module UriProcessorHelper
      class ErrorMonitor
        def initialize
          @error_count = 0
          @latest = nil
        end

        def good
          @error_count = 0
          @latest = nil
        end

        def bad
          @error_count += 1
          @latest = nil
          check_it
        end

        def failed
          @error_count += 1
          @latest = $!
          check_it
        end

        def check_it
          if @error_count >= 5
            if @latest
              puts @latest
              puts @latest.backtrace.join("\n")
            end
            raise IllegalStateError.new("Too many consecutive failures.")
          end
        end
      end

      def error_monitor
        begin
          @@error_monitor
        rescue
          @@error_monitor = ErrorMonitor.new
        end
      end
    end
  end
end
