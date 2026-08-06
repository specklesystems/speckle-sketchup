# frozen_string_literal: true

require_relative 'conversion_result'

module SpeckleConnector3
  module UiData
    module Report
      # Builds the DUI conversion-result rows for a 4.0 artifact receive
      # (ENG-9122): one row per source object (success / partial / skipped, keyed
      # by the object's application id), plus warning rows for definitions whose
      # member geometry was lost. Pure data-in data-out (no SketchUp dependency,
      # unit-testable headless) — {Converters::ToNativeV3} supplies what it
      # created, this module decides what the report says.
      module ReceiveReport
        # Geometry types {Converters::ToNativeV3#add_geometry} can bake; anything
        # else decodes but bakes to nothing and must be reported, not dropped.
        SUPPORTED_GEOMETRY_TYPES = %i[mesh line polyline].freeze

        module_function

        # One report row for a scene object. `created` summarises the native
        # entities the converter baked for it: [{id:, type:}, ...].
        def object_row(model, obj, created)
          issues = object_issues(model, obj)
          if created.any?
            status = issues.empty? ? ConversionStatus::SUCCESS : ConversionStatus::WARNING
            message = issues.empty? ? '' : "partially converted — #{issues.join('; ')}"
            ConversionResult.new(status, obj[:app_id].to_s, source_type(obj),
                                 created.first[:id], created.first[:type], message)
          else
            reason = issues.empty? ? 'no supported display geometry' : issues.join('; ')
            ConversionResult.new(ConversionStatus::WARNING, obj[:app_id].to_s, source_type(obj),
                                 nil, nil, "skipped — #{reason}")
          end
        end

        # A scene object whose bake raised: an ERROR row carrying the exception,
        # so one bad object surfaces without sinking the rest of the receive.
        def object_error_row(obj, error)
          ConversionResult.new(ConversionStatus::ERROR, obj[:app_id].to_s, source_type(obj),
                               nil, nil, error.message.to_s, error)
        end

        # WARNING rows for definitions with member geometry the receive can't
        # realize — definition members bake outside any scene object, so their
        # losses would otherwise vanish from the report entirely.
        def definition_rows(model)
          (model[:definitions] || {}).filter_map do |k, info|
            issues = (info[:geometry_ks] || []).filter_map { |geom_k| geometry_issue(model, geom_k) }
            next if issues.empty?

            ConversionResult.new(ConversionStatus::WARNING, info[:name] || "speckle_def_#{k}", 'Definition',
                                 nil, nil, issues.join('; '))
          end
        end

        # Everything about `obj` the converter cannot realize: displays whose
        # geometry is skipped/undecodable/unsupported and instance placements
        # whose instance or definition node is absent.
        def object_issues(model, obj)
          display = (obj[:displays] || []).filter_map { |geom_k| geometry_issue(model, geom_k) }
          instance = (obj[:display_instances] || []).filter_map do |inst_k|
            placement = (model[:instances] || {})[inst_k]
            if placement.nil?
              "instance #{inst_k} missing from bundle"
            elsif (model[:definitions] || {})[placement[:def_ref]].nil?
              "instance #{inst_k}: definition #{placement[:def_ref]} missing from bundle"
            end
          end
          display + instance
        end

        def geometry_issue(model, geom_k)
          geometry = (model[:geometries] || {})[geom_k]
          if geometry.nil?
            "geometry #{geom_k}: #{(model[:skipped_geometry] || {})[geom_k] || 'missing from bundle'}"
          elsif !SUPPORTED_GEOMETRY_TYPES.include?(geometry[:type])
            "geometry #{geom_k}: unsupported primitive '#{geometry[:primitive] || geometry[:type]}'"
          end
        end

        # The report's source vocabulary: the object's speckle_type leaf
        # ('Objects.Geometry.Mesh' -> 'Mesh'), 'Object' when the bundle has none.
        def source_type(obj)
          type = ((obj[:properties] || {})['speckle_type']).to_s
          type.empty? ? 'Object' : type.split('.').last
        end
      end
    end
  end
end
