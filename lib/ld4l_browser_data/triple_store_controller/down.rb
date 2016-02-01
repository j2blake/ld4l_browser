=begin rdoc
--------------------------------------------------------------------------------

If the currently-selected triple store is running, stop it.

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module TripleStoreController
    class Down
      def run
        begin
          selected = Selector.selected
          raise UserInputError.new("No triple-store selected") unless selected

          TripleStoreDrivers.select(selected)
          status = TripleStoreDrivers.status
          raise UserInputError.new("Triple-store is not running.") unless status.running?

          TripleStoreDrivers.shutdown
          puts
        rescue UserInputError
          puts
          puts "ERROR: #{$!}"
          puts
        end
      end
    end
  end
end
