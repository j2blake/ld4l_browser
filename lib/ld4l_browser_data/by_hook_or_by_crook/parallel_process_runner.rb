require 'childprocess'

module Ld4lBrowserData
  module ByHookOrByCrook
    class ParallelProcessRunner
      class Timeout < IllegalStateError
      end

      class Task
        attr_accessor :cmd
        attr_accessor :inputs
        attr_accessor :process
        attr_accessor :exit_code
        attr_accessor :running_time
      end

      DEFAULT_PARAMS = {
        timeout: 0,
        poll_interval: 10,
        inherit_output: true,
        sigint_on_failure: false,
      }

      def initialize(params)
        @settings = DEFAULT_PARAMS.merge(params)
        @tasks = []
        yield(self)
      end

      def task(*spec)
        t = Task.new
        if Array === spec[-1]
          inputs = spec.delete_at(-1)
          t.cmd = spec
          t.inputs = inputs
        else
          t.cmd = spec
        end
        @tasks << t
      end

      def run_processes
        @start_time = Time.now
        create_processes
        start_processes
        wait_for_processes
        assemble_results
      end
      
      def interrupt
        @interrupted = true
      end

      def create_processes
        @tasks.each do |t|
          t.process = create_process(t.cmd)
        end
      end

      def create_process(cmd)
        p = ChildProcess.build(*cmd)
        p.leader = true
        p.duplex = true
        p.io.inherit! if @settings[:inherit_output]
        return p
      end

      def start_processes
        @tasks.each do |t|
          start_process(t.process, t.inputs)
        end
      end

      def start_process(p, inputs)
        p.start
        if inputs
          inputs.each do |i|
            p.io.stdin.puts i
          end
          p.io.stdin.close
        end
      end

      def wait_for_processes
        loop do
          wait_and_mark_completed_tasks
          break if all_stopped?
          send_sigint if @settings[:sigint_on_failure] && any_failed?
          send_sigint if @interrupted
          raise Timeout.new if elapsed_time > @settings[:timeout]
        end
      end

      def wait_and_mark_completed_tasks
        sleep(@settings[:poll_interval])
        @tasks.each do |t|
          unless t.running_time
            if t.process.exited?
              t.running_time = elapsed_time
            end
          end
        end
      end

      def all_stopped?
        @tasks.all? { |t| t.running_time }
      end
      
      def any_failed?
        @tasks.any? { |t| t.process.exit_code && t.process.exit_code > 0 }
      end

      def send_sigint
        @tasks.each do |t|
          unless t.running_time
            begin
              `kill -sigint #{t.process.pid}`
            rescue
              puts "Failed to kill #{t.inspect}"
            end
          end
        end
      end

      def elapsed_time
        Time.now - @start_time
      end

      def assemble_results
        @tasks.map { |t| assemble_process_info(t) }
      end

      def assemble_process_info(t)
        {
          :cmd => t.cmd,
          :pid => t.process.pid,
          :exit_code => t.process.exit_code,
          :running_time => t.running_time,
        }
      end

      def to_s
        "ProcessMonitor: #{@tasks.inspect}"
      end
    end
  end
end
