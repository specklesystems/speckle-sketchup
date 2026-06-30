# frozen_string_literal: true

require_relative 'parquet_source'
require_relative 'sgeo_decoder'
require_relative 'vocab'

module SpeckleConnector3
  module Artifacts
    # Reads a 4.0 artefact bundle (our own UNCOMPRESSED parquet) back into a plain
    # structured model — the inverse of the producer, with NO SketchUp dependency
    # (so it is unit-testable headless). The native-entity creation consumes this.
    #
    # Returns a Hash:
    #   {
    #     collections: { node_k => { name:, parent_k:, subtype: } },   # tag/folder tree
    #     materials:   { node_k => { argb:, opacity:, metalness:, roughness: } },
    #     colors:      { node_k => argb },
    #     definitions: { node_k => { name:, geometry_ks: [...], instance_ks: [...] } },
    #     instances:   { node_k => { def_ref:, transform: [16 floats], units: } },
    #     geometries:  { geom_k => <decoded SGEO hash> },
    #     objects: [ { app_id:, collection_k:, color_argb:, is_soften:, properties: {path=>value},
    #                  displays: [geom_k...], display_instances: [inst_node_k...] } ],
    #     material_by_geom: { geom_k => material_node_k }
    #   }
    module BundleReader
      module_function

      def read(dir, base)
        env = ->(t) { ParquetSource.read_hashes(File.join(dir, "#{base}.envelope.#{t}.parquet")) }
        eav = ->(t) { ParquetSource.read_hashes(File.join(dir, "#{base}.eav.#{t}.parquet")) }

        nodes = index_by(env.call('nodes'), 'id')
        relations = env.call('relations')
        object_app = eav.call('objects').to_h { |r| [r['object_index'], r['application_id']] }
        paths = eav.call('paths').to_h { |r| [r['path_index'], r['path']] }
        props_by_obj = group_eav(eav.call('eav'), paths)
        geometries = read_geometries(dir, base)

        model = {
          collections: {}, materials: {}, colors: {}, definitions: {}, instances: {},
          geometries: geometries, objects: [], material_by_geom: {}
        }
        classify_nodes(nodes, model)
        wire_relations(relations, model, object_app, props_by_obj)
        model
      end

      # ── nodes ─────────────────────────────────────────────────────────

      def classify_nodes(nodes, model)
        nodes.each do |id, n|
          case n['kind']
          when NodeKind::COLLECTION
            model[:collections][id] = { name: n['name'], parent_k: n['def_ref'], subtype: n['units'] }
          when NodeKind::MATERIAL
            model[:materials][id] = {
              argb: n['argb'], opacity: n['opacity'], metalness: n['metalness'], roughness: n['roughness']
            }
          when NodeKind::COLOR
            model[:colors][id] = n['argb']
          when NodeKind::DEFINITION
            model[:definitions][id] = { name: n['name'], geometry_ks: [], instance_ks: [] }
          when NodeKind::INSTANCE
            model[:instances][id] = {
              def_ref: n['def_ref'], transform: parse_transform(n['transform']), units: n['units']
            }
          end
        end
      end

      # ── relations ─────────────────────────────────────────────────────

      def wire_relations(relations, model, object_app, props_by_obj)
        objects = {} # object_index => object hash (built lazily)
        obj = lambda do |oi|
          objects[oi] ||= begin
            props = props_by_obj[oi] || {}
            {
              app_id: object_app[oi], collection_k: nil, color_argb: nil,
              is_soften: props['@speckle.is_soften'], properties: props,
              displays: [], display_instances: []
            }
          end
        end

        relations.each do |r|
          rel = r['rel']
          src = r['src']
          dst = r['dst']
          case rel
          when RelKind::DISPLAY then obj.call(src)[:displays] << dst
          when RelKind::DISPLAY_INSTANCE then obj.call(src)[:display_instances] << dst
          when RelKind::IN_COLLECTION then obj.call(src)[:collection_k] = dst
          when RelKind::HAS_COLOR then obj.call(src)[:color_argb] = model[:colors][dst]
          when RelKind::HAS_MATERIAL then model[:material_by_geom][src] = dst
          when RelKind::DEFINES then model[:definitions][src][:geometry_ks] << dst if model[:definitions][src]
          when RelKind::DEFINES_INSTANCE then model[:definitions][src][:instance_ks] << dst if model[:definitions][src]
          end
        end

        model[:objects] = objects.values
      end

      # ── helpers ───────────────────────────────────────────────────────

      def read_geometries(dir, base)
        geom = {}
        Dir.glob(File.join(dir, "#{base}.geometries*.parquet")).each do |path|
          ParquetSource.read_hashes(path).each { |row| geom[row['geometryIndex']] = SgeoDecoder.decode(row['content']) }
        end
        geom
      end

      def group_eav(rows, paths)
        by_obj = Hash.new { |h, k| h[k] = {} }
        rows.each do |row|
          path = paths[row['path_index']]
          by_obj[row['object_index']][path] = eav_value(row)
        end
        by_obj
      end

      # Reconstructs the scalar value from the typed eav columns.
      def eav_value(row)
        return row['value_boolean'] unless row['value_boolean'].nil?
        return row['value_double'] unless row['value_double'].nil?

        row['value_string']
      end

      def parse_transform(str)
        return nil if str.nil?

        str.split(',').map(&:to_f)
      end

      def index_by(rows, key)
        rows.to_h { |r| [r[key], r] }
      end
    end
  end
end
