=begin rdoc
--------------------------------------------------------------------------------

Start with a directory filled with files of URIs. Consider each file as an
generating task. Run parallel processes to accomplish one task each, restarting
the triple-store as each set of processes is completed.

--------------------------------------------------------------------------------
=end
require "ld4l_browser_data/utilities/file_system_user"

require_relative 'wit_helper'
require_relative 'generator/report'

module Ld4lBrowserData
  module WhateverItTakes
    class Generator
      include Utilities::MainClassHelper
      include Utilities::FileSystemUser
      include WitHelper
      def initialize
        @usage_text = [
          'Usage is wit_generator \\',
          'source=<source_directory> \\',
          'file_system=<file_system_key>[~REPLACE] \\',
          'report_dir=<reports_directory>[~REPLACE] \\',
          'process_count=<number_of_processes> \\',
          '[how_many=<maximum_number_of_chunks>] \\',
          '[timeout=<maximum_seconds>] \\',
          '[RESTART] \\',
          '[IGNORE_BOOKMARKS] \\',
          '[IGNORE_SITE_SURPRISES] \\',
          '[SHOW_ALL_OUTPUT] \\',
        ]

        @valid_args = [
          :source,
          :file_system,
          :report_dir,
          :process_count,
          :how_many,
          :timeout,
          :RESTART,
          :IGNORE_BOOKMARKS,
          :IGNORE_SITE_SURPRISES,
          :SHOW_ALL_OUTPUT
        ]

        super
      end

      def process_arguments
        super
        @files = validate_file_system(:file_system, "file system key")
        @files_key = @args[:file_system]
      end

      def initialize_report
        @report = Report.new('wit_generator', File.join(@reports_dir, '_generator'))
      end

      def task_for_chunk(fn)
        source_file = File.join(@source_dir, fn)
        report_file = File.join(@reports_dir, fn)
        cmd = %W(ld4l_create_lod_files source=#{source_file} file_system=#{@files_key} report=#{report_file}~REPLACE)
        cmd << "IGNORE_BOOKMARK" if @ignore_bookmarks
        t = {
          name: fn,
          cmd:  cmd
        }
        @report.logit "Submitting task: #{t}"
        t
      end
    end
  end
end
