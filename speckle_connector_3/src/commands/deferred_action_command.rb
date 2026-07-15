# frozen_string_literal: true

require_relative 'command'

module SpeckleConnector3
  module Commands
    # An {ActionCommand} that runs its action on a short UI timer instead of
    # inside the JS->Ruby callback. Long operations (send/receive) block
    # SketchUp's main thread; deferring lets the HtmlDialog repaint first, so
    # the model card shows its progress state before everything freezes.
    #
    # The timer body replicates Command#run's protections (observers disabled +
    # HandleError) because the base wrapper returns before the timer fires.
    class DeferredActionCommand < Command
      # One frame is enough for CEF to paint the card's pending state.
      DEFER_DELAY_S = 0.15

      # @param app [App::SpeckleConnectorApp] the app object to run command on
      # @param binding [Ui::Binding] binding object holds commands to call
      # @param action [#update_state] the action that knows how to change the state of the speckle app
      def initialize(app, binding, action)
        super(app, binding)
        @action = action
      end

      private

      def _run(*parameters)
        UI.start_timer(DEFER_DELAY_S, false) do
          with_observers_disabled do
            app.update_state!(@action, *parameters)
          end
        rescue StandardError => e
          action = Actions::HandleError.new(e, @binding.nil? ? 'unknown binding' : @binding.name, @action, parameters)
          app.update_state!(action)
        end
      end
    end
  end
end
