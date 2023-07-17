# frozen_string_literal: true

require_relative 'view'
require_relative '../constants/path_constants'

require_relative '../actions/test_actions/say_hi'
require_relative '../actions/test_actions/go_away'
require_relative '../actions/test_actions/get_complex_type'
require_relative '../actions/test_actions/trigger_event'


module SpeckleConnector
  module Ui
    TEST_BINDINGS_VIEW = 'testBinding'

    # View that provided by vue.js
    class TestBindingsView < View
      CMD_UPDATE_VIEW = 'speckle.updateView'

      # @return [String] name of the view.
      attr_reader :name

      # @param app [App::SpeckleConnectorApp] the reference to the app object
      def initialize(app, name)
        super()
        @app = app
        @name = name
      end

      def update_view(_state)
        # TODO: If you want to send data to dialog additionally, consume this method.
        #  App object triggers this method by ui_controller
      end

      def commands
        @commands ||= {
          sayHi: Commands::ActionCommand.new(@app, self, Actions::SayHi),
          goAway: Commands::ActionCommand.new(@app, self, Actions::GoAway),
          getComplexType: Commands::ActionCommand.new(@app, self, Actions::GetComplexType),
          triggerEvent: Commands::ActionCommand.new(@app, self, Actions::TriggerEvent)
        }.freeze
      end
    end
  end
end
