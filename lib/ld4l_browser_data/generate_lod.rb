require 'fileutils'
require 'find'
require 'rdf'
require 'rdf/turtle'

require "ld4l_browser_data/utilities/file_system_user"
require "ld4l_browser_data/utilities/main_class_helper"
require "ld4l_browser_data/utilities/report_helper"
require "ld4l_browser_data/utilities/triple_store_user"

require_relative "generate_lod/linked_data_creator"
require_relative "generate_lod/list_uris"

def pattern_escape(string)
  string.gsub('/', '\\/').gsub('.', '\\.')
end

module Ld4lBrowserData
  module GenerateLod
  end
end

