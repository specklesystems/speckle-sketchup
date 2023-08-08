# frozen_string_literal: true

module SpeckleConnector
  module Ui
    # The abstract class for binding to send data to a user interface.
    class Binding
      # @return [String] name of the binding.
      attr_reader :name

      # @return [App::SpeckleConnectorApp] the reference to the app object
      attr_reader :app

      # @param app [App::SpeckleConnectorApp] the reference to the app object
      # @param name [String] name of the binding.
      def initialize(app, name)
        @app = app
        @name = name
      end

      def commands
        raise NotImplementedError, 'Implement in a subclass'
      end
    end
  end
end
