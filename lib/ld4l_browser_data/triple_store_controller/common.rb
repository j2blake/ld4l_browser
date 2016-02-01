=begin rdoc
--------------------------------------------------------------------------------

Establish the settings directory.

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module TripleStoreController
    SETTINGS_DIR = ENV['HOME'] + '/triple_store_settings'
    Dir.mkdir(SETTINGS_DIR) unless Dir.exist?(SETTINGS_DIR)
  end
end
