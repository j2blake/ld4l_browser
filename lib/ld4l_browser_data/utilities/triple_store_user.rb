require "ld4l_browser_data/triple_store_drivers"
require "ld4l_browser_data/triple_store_controller"

require_relative 'triple_store_user/query_runner'

module Ld4lBrowserData
  module Utilities
    module TripleStoreUser
      def connect_triple_store
        selected = TripleStoreController::Selector.selected
        raise UserInputError.new("No triple store selected.") unless selected

        TripleStoreDrivers.select(selected)
        @ts = TripleStoreDrivers.selected
        raise IllegalStateError.new("#{@ts} is not running") unless @ts.running?

        @report.logit("Connected to triple-store: #{@ts}") if @report
      end
    end
  end
end
