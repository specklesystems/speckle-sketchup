# frozen_string_literal: true

require_relative 'event_action'

module SpeckleConnector
  module Actions
    module Events
      class EntitiesEventAction < EventAction
        class OnElementAdded
          def self.update_state(state, event_data)
            # TODO: Do state updates when element added
            state
          end
        end

        class OnElementModified
          def self.update_state(state, event_data)
            # TODO: Do state updates when element modified
            state
          end
        end

        class OnElementRemoved
          def self.update_state(state, event_data)
            # TODO: Do state updates when element removed
            state
          end
        end

        # Handlers that are used to handle specific events
        ACTIONS = {
          onElementRemoved: OnElementRemoved,
          onElementAdded: OnElementAdded,
          onElementModified: OnElementModified
        }.freeze

        def self.actions
          ACTIONS
        end
      end
    end
  end
end
