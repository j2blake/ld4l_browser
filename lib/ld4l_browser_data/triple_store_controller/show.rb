=begin rdoc
--------------------------------------------------------------------------------

Show the status of the current triple_store (if any).

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module TripleStoreController
    class Show
      def show_none_selected()
        puts "No triple-store selected"
      end

      def show_selected()
        TripleStoreDrivers.select(@selected)
        ts = TripleStoreDrivers.selected

        puts TripleStoreDrivers.status.description
        puts "#{ts.size} triples." if ts.running?
      end

      def run
        begin
          @selected = Selector.selected

          puts
          if @selected
            show_selected
          else
            show_none_selected
          end
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
