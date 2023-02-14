# frozen_string_literal: true

require_relative 'action'

module SpeckleConnector
  module Actions
    # Adds material to speckle state and Sketchup.
    class AddMaterial < Action
      def self.update_state(state, material_name:, color:, material_id:, alpha: nil)
        materials = state.sketchup_state.materials
        existing_material = materials.by_id(material_id)
        return state if existing_material&.valid?

        new_material = create_or_get_material(state.sketchup_state.sketchup_model,
                                              material_name,
                                              color,
                                              material_id,
                                              alpha: alpha)
        new_materials = materials.add_material(material_id, new_material)
        new_sketchup_state = state.sketchup_state.with(:@materials => new_materials)
        state.with(:@sketchup_state => new_sketchup_state)
      end

      def self.create_or_get_material(model, material_name, color, material_id, alpha: nil)
        materials = model.materials
        existing_material = materials.find { |mat| mat.name == material_name }
        return existing_material if existing_material&.valid?

        existing_material = materials.add material_name
        existing_material.set_attribute(MAT_DICTIONARY, MAT_ID, material_id.to_s)
        set_hex_color(existing_material, color)
        existing_material.alpha = alpha if alpha
        existing_material
      end

      def self.set_hex_color(skp_material, hex_value)
        hex_value = hex_value.to_s
        col_blue, col_green, col_red = parse_hex_color(hex_value)
        skp_material.color = col_red, col_green, col_blue
      end

      def self.parse_hex_color(hex_value)
        split_values = hex_value.match(/^#([a-fA-F\d]{2})([a-fA-F\d]{2})([a-fA-F\d]{2})$/) ||
                       hex_value.match(/^#([a-fA-F\d])([a-fA-F\d])([a-fA-F\d])$/)
        col_red = split_values[1].hex
        col_green = split_values[2].hex
        col_blue = split_values[3].hex
        return col_blue, col_green, col_red
      end
    end
  end
end
