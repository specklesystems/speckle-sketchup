# frozen_string_literal: true

require_relative 'bindings/binding'
require_relative '../constants/path_constants'

require_relative '../actions/test_actions/say_hi'
require_relative '../actions/test_actions/go_away'
require_relative '../actions/test_actions/get_complex_type'
require_relative '../actions/test_actions/trigger_event'


module SpeckleConnector3
  module Ui
    TEST_BINDINGS_NAME = 'testBinding'

    # View that provided by vue.js
    class TestBinding < Binding
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
