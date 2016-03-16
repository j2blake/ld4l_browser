module Ld4lBrowserData
  module WhateverItTakes
    class CompileStats
      module Formats
        class Json
          def format(summary)
            JSON::pretty_generate(summary)
          end
        end
      end
    end
  end
end