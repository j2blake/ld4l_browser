=begin
--------------------------------------------------------------------------------

Write the report to a file, and to the console.

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module  GenerateLod
    class ListUris
      class Report
        include Utilities::ReportHelper
        def first_pass_start()
          @first_pass_start = Time.now
          @first_pass_recent = Time.now
          @first_pass_count = 0
          logit "Start first pass."
        end

        def first_pass_file(filename)
          @first_pass_count += 1
          #        logit "    processed #{filename}"
          if @first_pass_count % 100 == 0
            log_average_first_pass_files(filename)
          end
        end

        def log_average_first_pass_files(filename)
          elapsed = Time.now - @first_pass_recent
          logit ("                 %d files. Average of %6.3f seconds/file. %s" % [@first_pass_count, (elapsed/100), filename])
          @first_pass_recent = Time.now
        end

        def first_pass_stop()
          elapsed = Time.now - @first_pass_start
          logit "Stop first pass: #{@first_pass_count} files in #{elapsed} seconds."
          logit ("                 Average of %6.3f seconds/file." % (elapsed/@first_pass_count))
        end

        def merge_pass_start(source, target)
          logit "Start merge pass: #{File.basename(source)} to #{File.basename(target)}."
        end

        def merge_pass_stop(batches)
          logit "Stop merge pass: #{batches} batches."
        end

        def merge_passes_summary(last_file)
          logit "Merge passes complete: merged file is: #{last_file}"
        end

        def partition_complete(dirs)
          logit "Partitioned into \n   #{dirs.join"\n   "}"
        end

        def close()
          @file.close if @file
        end
      end
    end
  end
end
