require 'childprocess'

module Ld4lBrowserData
  module WhateverItTakes
    class ParallelProcessRunner
      class Timeout < IllegalStateError
      end

      class Task
        attr_accessor :name
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
        yield(self) if block_given?
      end

      def task(spec)
        t = Task.new
        raise UserInputError.new(':cmd is required on a task: #{spec.inspect}') unless spec[:cmd]
        t.cmd = make_array(spec[:cmd])
        t.inputs = make_array(spec[:inputs]) if spec[:inputs]
        t.name = spec[:name] || 'NO NAME'
        @tasks << t
      end

      def make_array(value)
        if Array === value
          value
        else
          [value]
        end
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
          run_for_a_while
          mark_completed_tasks
          break if all_stopped?
          send_sigint if @settings[:sigint_on_failure] && any_failed?
          shut_em_down if @interrupted
          raise Timeout.new if timed_out?
        end
      end

      def run_for_a_while
        sleep(@settings[:poll_interval])
      end

      def mark_completed_tasks
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
         failure = @tasks.find{ |t| t.process.exit_code && t.process.exit_code > 0 }
           if failure
             @report.logit("#{t.name} FAILED. Exit code: #{t.process.exit_code}")
             true
           else
             false
           end
      end

      def timed_out?
        @settings[:timeout] && @settings[:timeout] > 0 && elapsed_time > @settings[:timeout]
      end

      def send_sigint
        send_signals 'sigint'
      end
      
      def shut_em_down
        send_signals 'sigint'
        sleep 4
        send_signals '9'
      end

      def send_signals(signal)
        @tasks.each do |t|
          unless t.running_time
            begin
              `kill -#{signal} #{t.process.pid}`
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
          :name => t.name,
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
