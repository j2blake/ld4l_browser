require 'fileutils'
require 'find'
require 'rdf'
require 'rdf/raptor'

require "ld4l_browser_data/utilities/file_system_user"
require "ld4l_browser_data/utilities/main_class_helper"
require "ld4l_browser_data/utilities/report_helper"
require "ld4l_browser_data/utilities/triple_store_user"

require_relative "generate_lod/bookmark"
require_relative "generate_lod/counts"
require_relative "generate_lod/file_system"
require_relative "generate_lod/linked_data_creator"
require_relative "generate_lod/list_uris"
require_relative "generate_lod/query_runner"
require_relative "generate_lod/uri_discoverer"
require_relative "generate_lod/uri_processor"

def pattern_escape(string)
  string.gsub('/', '\\/').gsub('.', '\\.')
end

module Ld4lBrowserData
  module GenerateLod
  end
end

