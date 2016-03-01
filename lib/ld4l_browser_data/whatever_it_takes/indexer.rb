=begin rdoc
--------------------------------------------------------------------------------

Start with a directory filled with files of URIs. Consider each file as an
indexing task. Run parallel processes to accomplish one task each, restarting
the triple-store as each set of processes is completed.

--------------------------------------------------------------------------------
=end
require_relative 'indexer/report'

module Ld4lBrowserData
  module WhateverItTakes
    class Indexer
      include Utilities::MainClassHelper
      def initialize
        @usage_text = [
          'Usage is wit_indexer \\',
          'source=<source_directory> \\',
          'report_dir=<reports_directory>[~REPLACE] \\',
          'process_count=<number_of_processes> \\',
          '[how_many=<maximum_number_of_chunks>] \\',
          '[timeout=<maximum_seconds>] \\',
          '[RESTART] \\',
          '[IGNORE_SITE_SURPRISES] \\',
          '[SHOW_ALL_OUTPUT] \\',
        ]

        @uri_prefix = 'http://draft.ld4l.org/'

        @chunks_completed = 0
        @interrupted = false
        @start_time = Time.now
      end

      def process_arguments()
        parse_arguments(:source, :report_dir, :process_count, :how_many, :timeout, :RESTART, :IGNORE_SITE_SURPRISES, :SHOW_ALL_OUTPUT)

        @source_dir = validate_input_directory(:source, "source_directory")
        @reports_dir = validate_output_directory(:report_dir, "reports directory")
        @report = Report.new('wit_indexer', File.join(@reports_dir, '_indexer'))
        @process_count = validate_integer(key: :process_count, label: 'number of simultaneous processes', min: 1, max: 20)
        @how_many = validate_integer(key: :how_many, label: 'maximum number of chunks', min: 1, default: '10000')
        @timeout = validate_integer(key: :timeout, label: 'maximum seconds to run', default: '0')
        @restart = @args[:RESTART]
        @ignore_surprises = @args[:IGNORE_SITE_SURPRISES]
        @show_all_output = @args[:SHOW_ALL_OUTPUT]

        @report.log_header
      end

      def check_for_surprises
        check_site_consistency(@ignore_surprises, {
          'Source directory' => @source_files,
          'File system' => @files,
          'Report path' => @report
        })
      end

      def trap_control_c
        @interrupted = false
        trap("SIGINT") do
          @interrupted = true
          @report.logit "INTERRUPTED" if @report
          @process_runner.interrupt if @process_runner
        end
      end

      def do_rounds
        restart_if_requested
        while chunks_remain?
          cycle_triple_store
          @runner = create_process_runner
          get_next_chunks.map{ |c| task_for_chunk(c) }.each{ |t| @runner.task(t) }
          @results = @runner.run_processes
          @report.log_process_results(@results)
          mark_chunks_complete
        end
        @report.log_complete
      end

      def restart_if_requested
        @completed_dir = File.join(@source_dir, '_completed')
        Dir.mkdir(@completed_dir) unless File.exist?(@completed_dir)
        return unless @restart

        Dir.chdir(@completed_dir) do |d|
          files = source_files('.')
          files.each do |fn|
            `mv #{fn} ..`
          end
          @report.logit "Restored #{files.size} files."
        end
      end

      def chunks_remain?
        if source_files(@source_dir).empty?
          false
        elsif @chunks_completed >= @how_many
          false
        elsif @interrupted
          false
        else
          true
        end
      end

      def source_files(d)
        Dir.entries(d).reject{ |fn| fn.start_with?('.') || fn.start_with?('_') }
      end

      def cycle_triple_store
        bogus "cycle_triple_store DISABLED"
        return
        @report.logit `ts_down`
        @report.logit `ts_up`
      end

      def create_process_runner
        remaining_time = @timeout - (Time.now - @start_time)
        options = {poll_interval: 1, sigint_on_failure: true, timeout: remaining_time.to_i}
        @report.logit("Starting ParallelProcessRunner: #{options.inspect}")
        @runner = ParallelProcessRunner.new(options)
      end

      def get_next_chunks
        max = @how_many - @chunks_completed
        source_files(@source_dir)[0, max]
      end

      def task_for_chunk(fn)
        source_file = File.join(@source_dir, fn)
        report_file = File.join(@reports_dir, fn)
        t = {
          name: fn,
          cmd: %W(ld4l_index_specific_uris source=#{source_file} report=#{report_file})
        }
        @report.logit "Submitting task: #{t}"
        t
      end

      def mark_chunks_complete
        @results.each do |row|
          name, exit_code, running_time = row.values_at(:name, :exit_code, :running_time)
          if exit_code == 0
            @report.logit("#{name} completed successfully -- running time: #{running_time}.")
            `mv #{File.join(@source_dir, name)} @completed_dir`
          else
            @report.logit("#{name} failed -- exit code: #{exit_code}, running time: #{running_time}")
          end
        end
      end

      def run
        begin
          process_arguments
          check_for_surprises
          trap_control_c
          do_rounds
        rescue UserInputError, IllegalStateError
          puts
          puts "ERROR: #{$!}"
          puts
          exit 1
        ensure
          @report.close if @report
        end
      end
    end
  end
end
