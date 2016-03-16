require_relative 'formats/index_warnings'
require_relative 'formats/index_warnings_short'
require_relative 'formats/json'

module Ld4lBrowserData
  module WhateverItTakes
    class CompileStats
      module Formats
        class Indexing
        end

        FORMATTERS = {
          json: Json.new,
          indexing: Indexing.new,
          index_warnings: IndexWarnings.new,
          index_warnings_short: IndexWarningsShort.new
        }

        class << self
          def keys
            [:json, :indexing, :index_warnings, :index_warnings_short]
          end

          def formatter(key)
            FORMATTERS[key]
          end
        end

      end
    end
  end
end
