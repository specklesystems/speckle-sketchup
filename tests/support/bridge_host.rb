# frozen_string_literal: true

require 'json'
require_relative '../../speckle_connector_3/src/ext/immutable_ruby/core'
require_relative '../../speckle_connector_3/src/states/initial_state'
require_relative '../../speckle_connector_3/src/states/state'
require_relative '../../speckle_connector_3/src/states/speckle_state'
require_relative '../../speckle_connector_3/src/states/user_state'
require_relative '../../speckle_connector_3/src/relations/many_to_one_relation'
require_relative '../../speckle_connector_3/src/app/speckle_connector_app'

module SpeckleConnector3
  module TestSupport
    # Stands in for the DUI's HtmlDialog: keeps every script the app executes in it, which is how bindings
    # answer the DUI (`<binding>.receiveResponse('<request id>', <data>)`).
    class FakeDialog
      Response = Struct.new(:binding_name, :request_id, :data)

      attr_reader :scripts

      def initialize
        @scripts = []
      end

      def execute_script(script)
        @scripts << script
      end

      # @return [Array<Response>] the receiveResponse calls for `request_id`, in the order the dialog got them
      def responses_to(request_id)
        responses.select { |response| response.request_id == request_id }
      end

      def responses
        @scripts.filter_map do |script|
          match = script.match(/\A(\w+)\.receiveResponse\('([^']*)'(?:, (.*))?\)\z/m)
          match && Response.new(match[1], match[2], match[3] && JSON.parse(match[3]))
        end
      end
    end

    # The connector app as SketchUp runs it once Speckle is initialised (real state, message queue and flush),
    # with the HtmlDialog replaced by a FakeDialog and no model observers.
    module BridgeHost
      # @param unflushed [Array<Array>] `[action, *parameters]` already applied to the state but whose queued
      #   scripts have not reached the dialog yet
      def self.app(dialog, unflushed: [])
        speckle_state = States::SpeckleState.new([], {}, {}, {})
        state = States::State.new(States::UserState.new({}), speckle_state, nil, false, nil)
        state = unflushed.reduce(state) { |current, (action, *parameters)| action.update_state(current, *parameters) }
        ui_controller = Struct.new(:user_interfaces).new({ 'speckle_dui3' => dialog })
        App::SpeckleConnectorApp.new(nil, state, ui_controller)
      end
    end
  end
end
