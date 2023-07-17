# frozen_string_literal: true

module SpeckleConnector
  module Ui
    # The abstract class for view to send data to a user interface.
    class View

      attr_reader :name

      def update_view(_state)
        raise NotImplementedError, 'Implement in a subclass'
      end
    end
  end
end
