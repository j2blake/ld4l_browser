=begin

Create one of these for each test.

Create a Search page URL from the URI and try to fetch it. Report the results.

=end
require 'net/http'

module Ld4lBrowserData
  module SpotCheck
    class IndexChecker
      class UriProcessor
        def initialize(uri_info, report)
          @uri_info = uri_info
          @report = report
        end

        def test_it
          res = Net::HTTP.get_response(make_url)
          if res.code == '200'
            @report.success(@uri_info, res)
          else
            @report.failure(@uri_info, res)
          end
        end

        def make_url
          doc_id = uri_to_id(@uri_info[:uri])
          URI('http://search.ld4l.org/catalog/' + doc_id)
        end

        def uri_to_id(uri)
          uri.unpack('H*')[0]
        end
      end
    end
  end
end
