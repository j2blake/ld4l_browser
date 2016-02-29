module Ld4lBrowserData
  module ByHookOrByCrook
    class TestParallelProcessRunner
      def run
        pm = ParallelProcessRunner.new(timeout: 1000, poll_interval: 20, inherit_output: true, sigint_on_failure: true) do |pm|
          pm.task('ld4l_create_lod_files', 'source=list_all_uris/splits/split_aaab', 'file_system=mysql', 'report=_reports/create_lod_files_from_file.txt~REPLACE', 'IGNORE_BOOKMARK')
          pm.task('ld4l_ingest_directory_tree', 'source=raw_data/', 'site=cornell', 'report=_reports/ingest_raw_data.txt~REPLACE', ['yes'])
          #          pm.task('cat', ['first_line', 'second_line'])
          #          pm.task('sleep', '3')
          pm.task('cat', 'bogus')
        end

        puts pm
        results = pm.run_processes
        puts "Results: #{results.inspect}"
      end
    end
  end
end

