module Ld4lBrowserData
  module WhateverItTakes
    class CompileStats
      module Formats
        class IndexWarnings
          def format(summary)
            @summary = summary
            "%s%s%s" % [format_section("agents"), format_section("instances"), format_section("works")]
          end

          def format_section(key)
            @section = @summary[key]
            response = key.capitalize + format_count
            warnings.each do |k, w|
              @warning_key = k
              @warning = w
              response << format_warning
              response << format_examples
            end
            response << "\n"
          end

          def format_count
            count = @section["count"]
            if count
              ": total of %s\n" % count
            else
              "\n"
            end
          end

          def warnings
            @section["warnings"] || {}
          end

          def format_warning
            how_many = (@warning["count"] || "0").to_i
            "   %7d %s \n" % [how_many , @warning_key]
          end

          def format_examples
            "              %s \n" % @warning["examples"].join("\n              ")
          end
        end
      end
    end
  end
end
