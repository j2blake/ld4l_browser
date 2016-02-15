=begin
  A bookmark that stores to a document in the solr index. It holds both the
  document_type (to determine which query to issue) and the offet into the
  results of the query.
=end

module Ld4lBrowserData
  module Indexing
    class BuildSolrIndex
      class Bookmark
        include Utilities::BookmarkHelper
        def initialize(solr, restart)
          @document_id = 'bookmark_build_solr_index'
          @solr = solr
          super(restart, :offset => 0, :type_index => 0, :complete => false)
        end

        def increment
          @values[:offset] += 1
          persist if @values[:offset] % 100 == 0
        end

        def next_type()
          @values[:type_index] += 1
          @values[:offset] = 0
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
