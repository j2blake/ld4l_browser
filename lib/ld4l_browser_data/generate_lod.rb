require 'fileutils'
require 'find'
require 'rdf'
require 'rdf/raptor'

require "ld4l_browser_data/triple_store_drivers"
require "ld4l_browser_data/triple_store_controller"
require "ld4l_browser_data/utilities/triple_store_user"

require_relative "generate_lod/bookmark"
require_relative "generate_lod/counts"
require_relative "generate_lod/file_system"
require_relative "generate_lod/linked_data_creator"
require_relative "generate_lod/list_uris/list_uris"
require_relative "generate_lod/list_uris/report"
require_relative "generate_lod/query_runner"
require_relative "generate_lod/report"
require_relative "generate_lod/uri_discoverer"
require_relative "generate_lod/uri_processor"
require_relative "generate_lod/version"

module Ld4lBrowserData
  module GenerateLod
    def pattern_escape(string)
      string.gsub('/', '\\/').gsub('.', '\\.')
    end
  end
end

