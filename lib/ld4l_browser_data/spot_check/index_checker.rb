=begin rdoc
--------------------------------------------------------------------------------

Start with one or more directories, separated by commas. For each file of URIs
in the directories, pull a URI at intervals, create an index page URL from it,
and see whether that index page URL returns a page or an error.

Options: what size interval, stop after max URIs tested, skip files.

Log by file, wins/losses, and a sample of failing URIs.
Log totals, how many files, how many with failures, how many without failures,
            how many URIs, how many failures, how many successes.

--------------------------------------------------------------------------------
=end
require_relative "base_checker"
require_relative "index_checker/report"
require_relative "index_checker/uri_processor"

module Ld4lBrowserData
  module SpotCheck
    class IndexChecker
      include BaseChecker
      def initialize
        super('spotcheck_index')
      end

      def new_report(file, progress_interval)
        IndexChecker::Report.new('spotcheck_index', file, progress_interval)
      end

      def new_uri_processor(info, report)
        UriProcessor.new(info, @report)
      end
      
    end
  end
end

