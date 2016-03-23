require 'fileutils'

require_relative 'report'

module Ld4lBrowserData
  module WhateverItTakes
    module WitHelper
      def initialize
        @chunks_completed = 0
        @interrupted = false
        @failed = false
        @start_time = Time.now
      end

      def process_arguments()
        parse_arguments(*@valid_args)
        @source_dir = validate_input_directory(:source, "source_directory")
        @process_count = validate_integer(key: :process_count, label: 'number of simultaneous processes', min: 1, max: 40)
        @how_many = validate_integer(key: :how_many, label: 'maximum number of chunks', min: 1, default: '10000')
        @timeout = validate_integer(key: :timeout, label: 'maximum seconds to run', default: '0')
        @restart = @args[:RESTART]
        @ignore_bookmarks = @args[:IGNORE_BOOKMARKS]
        @ignore_surprises = @args[:IGNORE_SITE_SURPRISES]
        @show_all_output = @args[:SHOW_ALL_OUTPUT]
        @continue_on_failed_chunk = @args[:CONTINUE_ON_FAILED_CHUNK]

        @reports_dir = validate_output_directory(:report_dir, "reports directory")
        prepare_reports_directory
        @report = initialize_report
        @report.log_header
      end

      def prepare_reports_directory
        FileUtils.rm_r(@reports_dir) if Dir.exist?(@reports_dir)
        Dir.mkdir(@reports_dir)
      end

      def initialize_report
        raise NotImplementedError.new
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
          if @report
            @report.interrupted
          else
            puts "INTERRUPTED"
          end
          @runner.interrupt if @runner
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
        @failed_dir = File.join(@source_dir, '_failed')
        Dir.mkdir(@failed_dir) unless File.exist?(@failed_dir)
        return unless @restart

        Dir.chdir(@completed_dir) do |d|
          files = source_files('.')
          files.each do |fn|
            `mv #{fn} ..`
          end
          @report.restored_completed_files(files.size)
        end
        Dir.chdir(@failed_dir) do |d|
          files = source_files('.')
          files.each do |fn|
            `mv #{fn} ..`
          end
          @report.restored_failed_files(files.size)
        end
      end

      def source_files(d)
        Dir.entries(d).reject{ |fn| fn.start_with?('.') || fn.start_with?('_') }
      end

      def chunks_remain?
        if source_files(@source_dir).empty?
          false
        elsif @chunks_completed >= @how_many
          false
        elsif @interrupted || @failed
          false
        else
          true
        end
      end

      def cycle_triple_store
        @report.logit `ts_down`
        @report.logit `ts_up`
      end

      def create_process_runner
        remaining_time = @timeout - (Time.now - @start_time)
        options = {
          poll_interval: 1,
          sigint_on_failure: true,
          timeout: remaining_time.to_i,
          inherit_output: @show_all_output
        }
        @runner = ParallelProcessRunner.new(options, @report)
      end

      def get_next_chunks
        max = @how_many - @chunks_completed
        source_files(@source_dir)[0, max][0, @process_count]
      end

      def task_for_chunk(fn)
        raise NotImplementedError.new
      end

      def mark_chunks_complete
        @results.each do |row|
          name, exit_code, running_time = row.values_at(:name, :exit_code, :running_time)
          if exit_code == 0
            @report.chunk_completed(name, running_time)
            FileUtils.mv(File.join(@source_dir, name), @completed_dir)
            @chunks_completed += 1
          else
            @report.chunk_failed(name, running_time, exit_code)
            FileUtils.mv(File.join(@source_dir, name), @failed_dir)
            @failed = true unless @continue_on_failed_chunk
          end
        end
      end

      def run
        begin
          process_arguments
          check_for_surprises
          trap_control_c
          do_rounds
          exit 1 if @interrupted
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
