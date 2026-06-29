# frozen_string_literal: true

module SpeckleConnector3
  module Artifacts
    # EAV (Entity-Attribute-Value) property flattening — a pure-Ruby port of the
    # SDK's `Speckle.Sdk.Pipelines.Send.Artifacts.EavExtraction` (the native
    # Dictionary path). Behaviour-parity with the SDK / server TS is the goal;
    # quirks are intentionally preserved.
    #
    # Produces flat rows for the eav table keyed (externally) by the object's
    # applicationId. Each row: (path, value_text, value_num, type, unit,
    # internal_definition_name).
    module EavExtraction
      MAX_DEPTH = 10

      # Universal top-level keys under `properties` dropped for every object.
      DEFAULT_EXCLUDED_TOP_LEVEL = %w[Autodesk\ Material Document].freeze

      # Rejects UUID-like strings ("a-b-c" shapes) from numeric inference.
      UUID_LIKE = /.-.-/.freeze

      # One flat property row.
      EavRow = Struct.new(:path, :value_text, :value_num, :type, :unit, :internal_definition_name)

      module_function

      # Flattens one object's property tree.
      # @param properties [Hash] the nested `properties` dictionary
      # @param root_scalars [Array<Array(String, Object)>] bare top-level (key, value) labels
      # @param excluded [Array<String>] depth-0 keys to skip wholesale
      # @return [Array<EavRow>]
      def flatten_properties(properties, root_scalars = [], excluded: DEFAULT_EXCLUDED_TOP_LEVEL)
        rows = []
        root_scalars.each do |key, value|
          rows << make_row(key, value, nil, nil) if scalar?(value)
        end
        walk_properties(properties, 'properties', 0, rows, excluded)
        mq = properties['Material Quantities'] if properties.is_a?(Hash)
        extract_material_quantities(mq, rows) if mq.is_a?(Hash)
        rows
      end

      # Flattens a property SUBTREE under `prefix` (used for type_eav).
      def flatten_subtree(subtree, prefix)
        rows = []
        walk_properties(subtree, prefix, 0, rows, nil)
        rows
      end

      def walk_properties(obj, prefix, depth, rows, excluded)
        return if depth >= MAX_DEPTH
        return unless obj.is_a?(Hash)

        obj.each do |key, val|
          key = key.to_s
          next if depth.zero? && excluded && excluded.include?(key)
          next if val.nil?

          path = "#{prefix}.#{key}"

          if val.is_a?(Hash)
            # parameter pattern { name, value }
            if val.key?('name') && val.key?('value')
              param_val = val['value']
              next unless scalar?(param_val)

              units = val['units'].is_a?(String) ? val['units'] : nil
              idn = val['internalDefinitionName'].is_a?(String) ? val['internalDefinitionName'] : nil
              rows << make_row(path, param_val, units, idn)
              next
            end

            next if key == 'Structure' && prefix.end_with?('.Type Parameters')
            next if key == 'Material Quantities' # handled separately

            walk_properties(val, path, depth + 1, rows, nil)
            next
          end

          rows << make_row(path, val, nil, nil) if scalar?(val)
          # non-scalar, non-Hash (arrays, etc.) -> skipped, as in the SDK walk.
        end
      end

      def extract_material_quantities(mat_quants, rows)
        mat_quants.each do |mat_name, mat|
          next unless mat.is_a?(Hash)

          category = mat['materialCategory'].is_a?(String) ? mat['materialCategory'] : 'Unknown'
          append_quantity(mat, 'area', category, mat_name, rows)
          append_quantity(mat, 'volume', category, mat_name, rows)
        end
      end

      def append_quantity(mat, kind, category, mat_name, rows)
        q = mat[kind]
        return unless q.is_a?(Hash)

        value = q['value']
        return unless scalar?(value)

        units = q['units'].is_a?(String) ? q['units'] : nil
        rows << make_row("properties.Material Quantities.#{category}.#{mat_name}.#{kind}", value, units, nil)
      end

      def make_row(path, value, units, idn)
        type = infer_type(value)
        num = type == 'number' ? to_num(value) : nil
        EavRow.new(path, to_text(value), num, type, units, idn)
      end

      def scalar?(value)
        value.is_a?(String) || value.is_a?(Numeric) || value == true || value == false
      end

      def infer_type(value)
        case value
        when true, false then 'boolean'
        when Float then value.finite? ? 'number' : 'string'
        when Numeric then 'number'
        when String
          lower = value.downcase
          return 'boolean' if lower == 'true' || lower == 'false'

          trimmed = value.strip
          return 'string' if trimmed.empty? || UUID_LIKE.match?(trimmed)

          parse_finite_float(trimmed).nil? ? 'string' : 'number'
        else 'string'
        end
      end

      # JS String()/C# "R" semantics: lowercase booleans, integral floats without
      # a trailing ".0", other numbers/strings as-is.
      def to_text(value)
        case value
        when true then 'true'
        when false then 'false'
        when Integer then value.to_s
        when Float
          return value.to_s unless value.finite?

          iv = value.to_i
          iv == value ? iv.to_s : value.to_s
        else value.to_s
        end
      end

      def to_num(value)
        case value
        when String then parse_finite_float(value.strip)
        when Float then value.finite? ? value : nil
        when Numeric then value.to_f
        else nil
        end
      end

      # Parses a finite Float or returns nil (no exceptions, no Infinity/NaN).
      def parse_finite_float(str)
        f = Float(str)
        f.finite? ? f : nil
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
