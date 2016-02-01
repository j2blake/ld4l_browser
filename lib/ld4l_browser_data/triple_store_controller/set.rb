=begin rdoc
--------------------------------------------------------------------------------

Show the status of the current triple_store (if any). Offer to change to a
different one, unless the current one is running.

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module TripleStoreController
    class Set
      def offer_choice()
        @choices = Selector.available
        raise UserInputError.new('No settings files.') if @choices.empty?

        puts "Enter configuration number: "
        @choices.each_index do |index|
          puts "  #{index+1} = #{@choices[index][:name]}"
        end

        get_selection
        Selector.select(@selection)
        puts
        puts "#{@selection[:name]} selected."
      end

      def get_selection()
        input = STDIN.gets.chomp
        i = input.to_i
        raise UserInputError.new("Invalid index: #{input}") unless (1..@choices.length).include?(i)
        @selection = @choices[i - 1]
      end

      def run
        begin
          Show.new.run

          if TripleStoreDrivers.status.running?
            puts "Can't select a triple store while this one is running."
          else
            offer_choice
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
