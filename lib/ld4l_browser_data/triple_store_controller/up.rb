=begin rdoc
--------------------------------------------------------------------------------

If the currently-selected triple store is not running, start it running.

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module TripleStoreController
    class Up
      def run
        begin
          selected = Selector.selected
          raise UserInputError.new("No triple-store selected") unless selected

          TripleStoreDrivers.select(selected)
          status = TripleStoreDrivers.status
          raise UserInputError.new("Triple-store is already running.") if status.running?

          TripleStoreDrivers.startup
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