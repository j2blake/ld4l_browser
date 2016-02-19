=begin rdoc
--------------------------------------------------------------------------------

Maintain a bookmark file at the root of the nested directory structure.

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module GenerateLod
    class Bookmark
      attr_reader :filename
      attr_reader :offset
      attr_reader :start
      def initialize(process_id, files, restart)
        @key = process_id.to_s
        @files = files

        @settings = @files.get_bookmark(@key)
        if @settings && !restart
          load
        else
          reset
          persist
        end

        @start = map_it
      end

      def load()
        @filename = @settings[:filename] || ''
        @offset = @settings[:offset] || 0
        @complete = @settings[:complete] || false
      end

      def reset
        @filename = ''
        @offset = 0
        @complete = false
      end

      def persist()
        @files.set_bookmark(@key, map_it)
      end

      def map_it
        {:filename => @filename, :offset => @offset, :complete => @complete}
      end

      def update(filename, offset)
        @offset = offset
        @filename = filename
        persist
      end

      def set_offset(offset)
        @offset = offset
        persist
      end

      def complete()
        @complete = true
        persist
      end

      def complete?
        @complete
      end

      def clear()
        @files.clear_bookmark(@key)
      end
    end
  end
end
