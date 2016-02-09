module Ld4lBrowserData
  module Utilities
    module SolrServerUser
      SOLR_BASE_URL = 'http://localhost:8983/solr/blacklight-core'
      def connect_solr_server(clear)
        @ss = SolrServer.new(SOLR_BASE_URL)
        raise UserInputError.new("#{@ss} is not running") unless @ss.running?

        if clear
          if confirm_intentions?
            @ss.clear
          else
            raise UserInputError.new("OK. Skip it.")
          end
        end
      end

      def confirm_intentions?
        puts "Solr contains #{@ss.num_docs} documemts."
        puts "Delete them? (yes/no) ?"
        'yes' == STDIN.gets.chomp
      end
    end
  end
end
