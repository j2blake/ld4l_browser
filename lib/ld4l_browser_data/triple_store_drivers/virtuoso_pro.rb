=begin
Driver for the commercial version of Virtuoso.

So far, the only differences we know about are in virtuoso.ini
=end
module Ld4lBrowserData
  module TripleStoreDrivers
    class VirtuosoPro < Virtuoso
      def template_file
        'virtuoso_pro.ini.template'
      end
    end
  end
end
