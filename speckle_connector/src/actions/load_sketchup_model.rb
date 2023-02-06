# frozen_string_literal: true

require_relative 'action'
require_relative '../states/state'
require_relative '../constants/observer_constants'

module SpeckleConnector
  module Actions
    # Switch sketchup model wit a new one
    class LoadSketchupModel < Action
      # Replace current model state with the state of a new model. This action is triggered when user opens new or
      # existing Sketchup model.
      # @param state [States::State] the current state of Speckle
      # @param additional_parameters [Array] parameters that the action takes
      # @return [States::State] the new updated state object
      def self.update_state(state, sketchup_model)
        # new_model_state = SketchupModel::Readers::ModelReader.read_model(sketchup_model)
        # new_model_state = InitializeMaterials.update_state(new_model_state)
        new_sketchup_state = state.sketchup_state.with(:@sketchup_model => sketchup_model)
        new_state = state.with(:@sketchup_state => new_sketchup_state)
        attach_observers(sketchup_model, new_state.speckle_state.observers)
        new_state
      end

      # Attach observers to the sketchup model
      # @param sketchup_model [Sketchup::Model] the model to attach observers to
      # @param observers [Hash{Class=>}] the observer objects indexed by their class that will be attached
      def self.attach_observers(sketchup_model, observers)
        # selection = sketchup_model.selection
        # selection.add_observer(observers[SELECTION_OBSERVER_NAME])
        # layers = sketchup_model.layers
        # layers.add_observer(observers[LAYERS_OBSERVER_NAME])
        entities = sketchup_model.entities
        entities.add_observer(observers[ENTITIES_OBSERVER])
        # sketchup_model.add_observer(observers[MODEL_OBSERVER])
        # materials = sketchup_model.materials
        # materials.add_observer(observers[MATERIALS_OBSERVER_NAME])
        # pages = sketchup_model.pages
        # pages.add_observer(observers[PAGES_OBSERVER_NAME])
      end
    end
  end
end
