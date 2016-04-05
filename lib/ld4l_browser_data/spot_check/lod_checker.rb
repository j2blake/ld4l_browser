=begin rdoc
--------------------------------------------------------------------------------

Same as spotcheck index, but each URI is tested against the LOD server.

--------------------------------------------------------------------------------
=end
require_relative "base_checker"
require_relative "index_checker/report"
require_relative "lod_checker/uri_processor"

module Ld4lBrowserData
  module SpotCheck
    class LODChecker
      include BaseChecker
      def initialize
        super('spotcheck_lod')
      end

      def new_report(file, progress_interval)
        IndexChecker::Report.new('spotcheck_lod', file, progress_interval)
      end

      def new_uri_processor(info, report)
        UriProcessor.new(info, @report)
      end
      
    end
  end
end
