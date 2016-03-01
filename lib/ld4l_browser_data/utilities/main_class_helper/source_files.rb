module Ld4lBrowserData
  module Utilities
    module MainClassHelper
      class SourceFiles
        def initialize(path)
          raise IllegalStateError.new("#{path} doesn't exist.") unless File.exist?(path)
          @path = File.expand_path(path)
        end

        def basename
          File.basename(@path)
        end

        def each
          if File.directory?(@path)
            Dir.chdir(@path) do |d|
              Dir.entries(d).sort.each do |fn|
                File.open(fn) do |f|
                  yield f
                end
              end
            end
          else
            File.open(@path) do |f|
              yield f
            end
          end
        end
      end
    end
  end
end
