# frozen_string_literal: true

require_relative '../action'
require_relative '../../sketchup_model/query/entity'
require_relative '../../sketchup_model/utils/view_utils'

module SpeckleConnector
  module Actions
    # Action to add send card.
    class HighlightObjects < Action
      def self.update_state(state, resolve_id, object_ids)
        SketchupModel::Utils::ViewUtils.highlight_entities(state.sketchup_state.sketchup_model, object_ids)

        # Resolve promise
        js_script = "baseBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('highlightObjects', js_script)
      end
    end
  end
end
