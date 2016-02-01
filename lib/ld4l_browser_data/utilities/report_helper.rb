module Ld4lBrowserData
  module Utilities
    module ReportHelper
      def initialize(main_routine, path)
        @main_routine = main_routine
        @file = File.open(path, 'w')
      end

      def logit(message)
        m = "#{Time.new.strftime('%Y-%m-%d %H:%M:%S')} #{message}"
        puts m
        @file.puts m
      end

      def log_header(args)
        logit "#{@main_routine} #{args.join(' ')}"
      end

      def close
        @file.close if @file
      end
    end
  end
end