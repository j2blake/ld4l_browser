module Ld4lBrowserData
  module Utilities
    module ReportHelper
      #
      # Record stdout and stderr, even while they are being displayed.
      #
      class MultiIO
        def initialize(*targets)
          @targets = targets
        end

        def write(*args)
          @targets.each {|t| t.write(*args)}
        end

        def flush()
          @targets.each(&:flush)
        end

        def close
          @targets.each(&:close)
        end
      end

      def initialize(main_routine, path)
        @main_routine = main_routine
        
        @file = File.open(path, 'w')
        @file.sync = true
        $stdout = MultiIO.new($stdout, @file)
        $stderr = MultiIO.new($stderr, @file)
      end

      def logit(message)
        puts "#{Time.new.strftime('%Y-%m-%d %H:%M:%S')} #{message}"
      end
      
      def log_only(message)
        @file.puts "#{Time.new.strftime('%Y-%m-%d %H:%M:%S')} #{message}"
      end

      def log_header()
        logit "#{@main_routine} #{ARGV.join(' ')}"
      end

      def nothing_to_do
        logit("The bookmark says that processing is complete.")
      end

      def summarize_http_status(ts)
        begin
          return unless ts
          return unless ts.respond_to?(:http_counts)
          
          counts = ts.http_counts
          return unless counts
          
          total = counts.reduce(0) {|sum, m| sum += m[1].values.reduce(0, :+)} 
          return unless total > 0
          
          logit "http counts: #{counts.inspect}, total = #{total}"
        rescue
          logit "No HTTP status: #{$!}"
        end
      end

      def close
        @file.close if @file
      end
      
      def to_s
        "Report: '#{@file.path}'"
      end
    end
  end
end