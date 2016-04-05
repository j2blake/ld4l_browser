=begin

Create one of these for each test.

The the URI as a URL. If the response is a redirect, follow it.

=end
require 'net/http'

module Ld4lBrowserData
  module SpotCheck
    class LODChecker
      class UriProcessor
        def initialize(uri_info, report)
          @uri_info = uri_info
          @report = report
        end

        def test_it
          res = Net::HTTP.get_response(make_url)

          if res.code.start_with?('3')
            res = Net::HTTP.get_response(URI.parse(res.header['location']))
          end

          if res.code == '200'
            @report.success(@uri_info, res)
          else
            @report.failure(@uri_info, res)
          end
        end

        def make_url
          URI(@uri_info[:uri])
        end
      end
    end
  end
end
