=begin

Accumulate the warnings, and some examples of the URIs that cause them

For each marning message, record the number of times it occurs and the first 10
URIs that produced it.

=end
require 'ostruct'

module Ld4lBrowserData
  module Utilities
    class WarningsCounter
      class Warning
        EXAMPLES_LIMIT = 10

        attr_accessor :count
        attr_accessor :examples
        def initialize
          @count = 0
          @examples = []
        end

        def add(uri)
          @count += 1
          @examples << uri if @examples.size < EXAMPLES_LIMIT
        end

        def to_json(*a)
          {
            count: @count,
            examples: @examples,
          }.to_json(*a)
        end
      end

      def initialize
        @items = Hash.new do |h, k|
          h[k] = Warning.new
        end
      end

      def record_warning(message, uri)
        @items[message].add(uri)
      end

      def items
        @items.keys.sort().map do |message|
          item = @items[message]
          OpenStruct.new(message: message, count: item.count, examples: item.examples)
        end
      end

      def empty?
        @items.size == 0
      end

      def to_json(*a)
        @items.to_json(*a)
      end
    end
  end
end
