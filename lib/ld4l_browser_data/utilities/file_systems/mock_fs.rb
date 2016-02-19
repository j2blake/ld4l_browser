module Ld4lBrowserData
  module Utilities
    module FileSystems
      class MockFS
        def initialize(settings)
        end

        def get_bookmark(key)
          bogus "get_bookmark(#{key})"
          nil
        end

        def set_bookmark(key, contents)
          bogus "set_bookmark(#{key}, #{contents.inspect})"
        end

        def acceptable?(uri)
          true
        end

        def write(uri, contents)
          bogus "write(#{uri}}"
        end

        def set_void(filename, contents)
          bogus "set_void(#{filename})"
        end

        def close
          bogus "close"
        end
      end
    end
  end
end