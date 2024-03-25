# frozen_string_literal: true

require_relative 'action'
require_relative 'initialize_materials'
require_relative '../sketchup_model/reader/speckle_entities_reader'
require_relative '../sketchup_model/reader/mapper_reader'
require_relative '../preferences/preferences'
require_relative '../states/state'
require_relative '../states/sketchup_state'
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
        # Init sketchup state again with new model
        new_sketchup_state = States::SketchupState.new(sketchup_model)
        sketchup_model.rendering_options['DisplaySectionPlanes'] = true
        new_state = state.with(:@sketchup_state => new_sketchup_state)
        # Init materials again
        new_state = InitializeMaterials.update_state(new_state)

        # Read speckle entities
        new_speckle_entities = SketchupModel::Reader::SpeckleEntitiesReader.read(sketchup_model.entities)
        new_speckle_state = new_state.speckle_state.with_speckle_entities(Immutable::Hash.new(new_speckle_entities))
        # Read mapped entities
        new_mapped_entities = SketchupModel::Reader::MapperReader.read_mapped_entities(sketchup_model.entities)
        new_speckle_state = new_speckle_state.with_mapped_entities(Immutable::Hash.new(new_mapped_entities))
        new_state = new_state.with_speckle_state(new_speckle_state)

        # Read preferences from database and model.
        preferences = Preferences.read_preferences(new_state.sketchup_state.sketchup_model)
        new_user_state = new_state.user_state.with_preferences(preferences)
        new_state = new_state.with(:@user_state => new_user_state)
        attach_observers(sketchup_model, new_state.speckle_state.observers)
        new_state
      end

      # Attach observers to the sketchup model
      # @param sketchup_model [Sketchup::Model] the model to attach observers to
      # @param observers [Hash{Class=>}] the observer objects indexed by their class that will be attached
      def self.attach_observers(sketchup_model, observers)
        selection = sketchup_model.selection
        selection.add_observer(observers[SELECTION_OBSERVER])
        # layers = sketchup_model.layers
        # layers.add_observer(observers[LAYERS_OBSERVER_NAME])
        entities = sketchup_model.entities
        edges = entities.grep(Sketchup::Edge)
        edges.each { |edge| edge.add_observer(observers[ENTITY_OBSERVER]) }
        entities.add_observer(observers[ENTITIES_OBSERVER])
        sketchup_model.add_observer(observers[MODEL_OBSERVER])
        # materials = sketchup_model.materials
        # materials.add_observer(observers[MATERIALS_OBSERVER_NAME])
        # pages = sketchup_model.pages
        # pages.add_observer(observers[PAGES_OBSERVER_NAME])
      end
    end
  end
end
