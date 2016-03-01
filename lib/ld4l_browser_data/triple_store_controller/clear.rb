=begin rdoc
--------------------------------------------------------------------------------

If the currently-selected triple store is not running, and if clearing the triple
store is permitted by the settings, and if the user confirms the intention,
clear the triple store.

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module TripleStoreController
    class Clear
      def confirm_intentions(ts)
        puts "REALLY clear the triples from #{ts} (yes/no) ?"
        'yes' == STDIN.gets.chomp
      end

      def run
        begin
          selected = Selector.selected
          raise UserInputError.new("No triple-store selected") unless selected

          TripleStoreDrivers.select(selected)
          status = TripleStoreDrivers.status
          raise UserInputError.new("Stop the triple-store first") if status.running?

          ts = TripleStoreDrivers.selected
          raise UserInputError.new("#{ts} can only be cleared manually.") unless ts.clear_permitted?

          if confirm_intentions(ts)
            puts "Clearing #{ts}"
            ts.clear
            puts 'Cleared.'
          else
            puts 'Skip it.'
          end

          puts
        rescue UserInputError
          puts
          puts "ERROR: #{$!}"
          puts
          exit 1
        end
      end
    end
  end
end
