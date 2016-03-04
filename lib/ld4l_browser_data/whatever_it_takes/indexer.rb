=begin rdoc
--------------------------------------------------------------------------------

Start with a directory filled with files of URIs. Consider each file as an
indexing task. Run parallel processes to accomplish one task each, restarting
the triple-store as each set of processes is completed.

--------------------------------------------------------------------------------
=end
require_relative 'wit_helper'

module Ld4lBrowserData
  module WhateverItTakes
    class Indexer
      include Utilities::MainClassHelper
      include WitHelper
      def initialize
        @usage_text = [
          'Usage is wit_indexer \\',
          'source=<source_directory> \\',
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
      
      def initialize_report
        @report = Report.new('wit_indexer', File.join(@reports_dir, '_indexer'))
      end

      def task_for_chunk(fn)
        source_file = File.join(@source_dir, fn)
        report_file = File.join(@reports_dir, fn)
        cmd = %W(ld4l_index_specific_uris source=#{source_file} report=#{report_file}~REPLACE)
        cmd << "IGNORE_BOOKMARK" if @ignore_bookmarks
        t = {
          name: fn,
          cmd:  cmd
        }
        @report.submitting_task(t)
        t
      end

    end
  end
end

''