=begin
=end
require 'fileutils'

module Ld4lBrowserData
  module Utilities
    module BookmarkHelper
      def initialize(reset, defaults)
        if reset
          @values = defaults
        elsif loaded = load
          @values = loaded
        else
          @values = defaults
        end
        persist

        @start = Hash[@values]
      end

      def load
        json = retrieve
        if json
          JSON.parse(json, :symbolize_names => true)
        else
          nil
        end
      end

      def persist
        store JSON.generate(@values)
      end

      def clear
        remove
      end

      def [](key)
        @values[key]
      end

      def []=(key, value)
        @values[key] = value
      end

      def complete
        @values[:complete] = true
        persist
      end

      def complete?
        @values[:complete]
      end

      def start
        @start
      end
      
      #
      # Override these stub methods
      #

      # store a JSON-encoded bookark string.
      def store(json)
      end

      # get the JSON-encoded bookmark string, or nil.
      def retrieve
        nil
      end

      # remove the bookmark from storage.
      def remove
      end

    end
  end
end
