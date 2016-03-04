require 'mysql2'

module Ld4lBrowserData
  module Utilities
    module FileSystems
      class MySqlFS
        DEFAULT_PARAMS = {
          :host => 'localhost',
          :username => 'SUPPLY_USERNAME',
          :password => 'SUPPLY_PASSWORD',
          :database => 'ld4l',
        }

        def initialize(params)
          @settings = DEFAULT_PARAMS.merge(params)
          @client = Mysql2::Client.new(@settings)
          @read_statement = @client.prepare('SELECT rdf FROM lod WHERE uri = ?')
          @insert_statement = @client.prepare('INSERT INTO lod SET uri = ?, rdf = ?')
          @update_statement = @client.prepare('INSERT INTO lod SET uri = ?, rdf = ? ON DUPLICATE KEY UPDATE rdf = ?')
        end

        def get_bookmark(key)
          result = @read_statement.execute('bookmark_' + key)
          row = result.first
          if row && row['rdf']
            bkmk = JSON.parse(row['rdf'], :symbolize_names => true)
            bkmk
          else
            nil
          end
        end

        def set_bookmark(key, contents)
          insert('bookmark_' + key, JSON.generate(contents))
        end

        def acceptable?(uri)
          true
        end

        def write(uri, contents)
          bogus("Size of RDF is %d for %s" % [contents.size, uri]) if contents.size >= 2**16
          insert(uri, contents)
        end

        def insert(uri, rdf)
          begin
            @insert_statement.execute(uri, rdf)
          rescue
            @update_statement.execute(uri, rdf, rdf)
          end
        end

        def close()
          @client.close
        end
      end
    end
  end
end