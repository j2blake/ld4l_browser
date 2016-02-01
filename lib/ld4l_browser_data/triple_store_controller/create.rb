=begin rdoc
--------------------------------------------------------------------------------

If the currently-selected triple store is not running, check to see whether the
described data-store already exists. If yes, complain. If no, create it.

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module TripleStoreController
    class Create
      def run
        begin
          selected = Selector.selected
          raise UserInputError.new("No triple-store selected") unless selected

          TripleStoreDrivers.select(selected)
          status = TripleStoreDrivers.status
          raise UserInputError.new("Stop the triple-store first") if status.running?

          ts = TripleStoreDrivers.selected

          puts "Creating #{ts}"
          ts.create
          puts 'Created.'
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
