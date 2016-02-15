module Ld4lBrowserData
  module Indexing
    class IndexSpecificUris
      class Bookmark
        include Utilities::BookmarkHelper
        def initialize(id, solr, restart)
          @document_id = 'bookmark_index_specific_uris_' + id.to_s
          @solr = solr
          super(restart, :offset => 0, :filename => '', :complete => false)
        end

        def update(filename, offset)
          @values[:filename] = filename
          @values[:offset] = offset
          persist
        end

        def store(json)
          @solr.add_document({:id => @document_id, :json_display => json})
        end

        def retrieve()
          response = @solr.get_document(@document_id)
          if response['response']['numFound'] == 0
            nil
          else
            response['response']['docs'][0]['json_display'][0]
          end
        end

        def remove
          @solr.delete_by_id(@document_id)
        end
      end
    end
  end
end