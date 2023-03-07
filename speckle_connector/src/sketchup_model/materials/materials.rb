# frozen_string_literal: true

require_relative '../../constants/mat_constants'

module SpeckleConnector
  # Operations related to {SketchupModel}.
  module SketchupModel
    # Materials to store for entities.
    class Materials
      def self.from_sketchup_model(model)
        materials = model.materials
        materials = materials.select do |material|
          !material.attribute_dictionaries.nil? &&
            material.attribute_dictionaries.any? { |dict| dict.name == MAT_DICTIONARY }
        end
        mat_hash = materials.collect { |material| [material.get_attribute(MAT_DICTIONARY, MAT_ID), material] }.to_h
        Materials.new(mat_hash)
      end

      def initialize(material_hash = {})
        @materials_by_id = material_hash.freeze
        @id_by_materials = material_hash.collect { |id, material| [material, id] }.to_h.freeze
        freeze
      end

      def add_material(id, material)
        old_material = @materials_by_id[id.to_sym]
        return self if material == old_material

        new_material_hash = @materials_by_id.merge({ id.to_sym => material })
        Materials.new(new_material_hash)
      end

      def by_id(id)
        @materials_by_id[id.to_sym]
      end

      def material_id(material)
        @id_by_materials[material]
      end

      def add_speckle_material
        @materials_by_id[MAT_ADD]
      end

      def edit_speckle_material
        @materials_by_id[MAT_EDIT]
      end

      def remove_speckle_material
        @materials_by_id[MAT_REMOVE]
      end
    end
  end
end
