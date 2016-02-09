require 'json'
require 'rdf'
require 'rdf/ntriples'
require "ld4l_browser_data/triple_store_drivers"
require "ld4l_browser_data/triple_store_controller"
require "ld4l_browser_data/utilities/main_class_helper"
require "ld4l_browser_data/utilities/report_helper"
require "ld4l_browser_data/utilities/solr_server"
require "ld4l_browser_data/utilities/solr_server_user"
require "ld4l_browser_data/utilities/triple_store_user"

require_relative "indexing/build_solr_index"
#require "ld4l_indexing/sample_solr_index"
require_relative "indexing/bookmark"
require_relative "indexing/counts"
require_relative "indexing/document_factory"
require_relative "indexing/document_stats_accumulator"
#require "ld4l_indexing/index_chosen_uris"
require_relative "indexing/language_reference"
require_relative "indexing/query_runner"
require_relative "indexing/report"
require_relative "indexing/topic_reference"
require_relative "indexing/uri_discoverer"
require_relative "indexing/document_base"
require_relative "indexing/agent_document"
require_relative "indexing/instance_document"
require_relative "indexing/work_document"

module Ld4lBrowserData
  module Indexing
    # Couldn't fully create the document
    class DocumentError < StandardError
      attr_reader :cause
      attr_reader :doc
      def initialize(cause, doc)
        @cause = cause
        @doc = doc
      end
    end
  end
end
