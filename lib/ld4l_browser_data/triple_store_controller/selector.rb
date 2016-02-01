=begin rdoc
--------------------------------------------------------------------------------

Find what settings are available to choose from, and what has been chosen.
Record a new choice, if asked.

Different configurations are stored in executable ".settings" files. Each one
contains a Hash with the settings values.

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module TripleStoreController
    class Selector
      SETTINGS_FILE = SETTINGS_DIR + '/current'
      class << self
        def available
          Dir.chdir(SETTINGS_DIR) do |d|
            Dir.entries(d).each.select { |fn|
              fn.end_with?('.settings')
            }.map { |fn|
              eval(File.read(fn))
            }.sort { |a, b|
              (a[:name] || '') <=> (b[:name] || '')
            }
          end
        end

        def selected
          if @selection
            @selection
          elsif File.exist?(SETTINGS_FILE)
            @selection = eval(File.read(SETTINGS_FILE))
          else
            nil
          end
        end

        def select(settings)
          File.open(SETTINGS_FILE, 'w') do |f|
            f.puts "# set at #{Time.now}"
            f.puts settings.inspect
          end
          @selection = settings
        end
      end
    end
  end
end
