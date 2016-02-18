require 'json'
require 'rdf'
require 'rdf/ntriples'
require "ld4l_browser_data/utilities/bookmark_helper"
require "ld4l_browser_data/utilities/main_class_helper"
require "ld4l_browser_data/utilities/report_helper"
require "ld4l_browser_data/utilities/solr_server"
require "ld4l_browser_data/utilities/solr_server_user"
require "ld4l_browser_data/utilities/triple_store_user"

require_relative "indexing/common/counts"
require_relative "indexing/common/language_reference"
require_relative "indexing/common/query_runner"
require_relative "indexing/common/topic_reference"

require_relative "indexing/index_documents"
require_relative "indexing/build_solr_index"
require_relative "indexing/sample_solr_index"
require_relative "indexing/index_specific_uris"
require_relative "indexing/report"

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
