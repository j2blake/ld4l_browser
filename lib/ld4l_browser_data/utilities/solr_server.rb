require 'rubygems'
require 'rsolr'

module Ld4lBrowserData
  module Utilities
    class SolrServer
      def initialize(solr_url)
        @solr_url = solr_url
        @solr = RSolr.connect(:url => solr_url)
      end

      def running?
        begin
          result = @solr.select(:params => {:q => "bogus"})
          true
        rescue
          false
        end
      end

      #  def clear()
      #    @solr.delete_by_query("*:*")
      #  end

      def add_document(doc)
        begin
          @solr.add doc
        rescue RSolr::Error::Http
          puts "solr failed 1"
          begin
            @solr.add doc
          rescue RSolr::Error::Http
            puts "solr failed 2"
            @solr.add doc
          end
        end
      end

      def get_document(id)
        @solr.get('select', :params => { :qt => 'document', :id => id })
      end

      def query(params)
        @solr.get('select', :params => params)
      end

      def commit()
        @solr.commit
      end

      def delete_by_id(id)
        @solr.delete_by_id([id])
        @solr.commit
      end

      def clear()
        @solr.delete_by_query('*:*')
        @solr.commit
      end

      def num_docs()
        @solr.get('select', :params => {:rows => 0})['response']['numFound']
      end

      def to_s
        "Solr server at #{@solr_url}"
      end
    end
  end
end
