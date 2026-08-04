# frozen_string_literal: true

require_relative 'parquet/parquet_table_writer'
require_relative 'id_interner'

module SpeckleConnector3
  module Artifacts
    # Writes the six `{base}.eav.*.parquet` tables (object/path/type dictionaries +
    # instance- and type-scoped property rows). Mirrors the SDK `EavWriter`:
    # first-seen dense-int interning of applicationId / path / type_key, type dedup.
    class EavWriter
      OBJECTS_SCHEMA = [
        { name: 'object_index', type: :int32, optional: false },
        { name: 'application_id', type: :string, optional: true }
      ].freeze

      PATHS_SCHEMA = [
        { name: 'path_index', type: :int32, optional: false },
        { name: 'path', type: :string, optional: true }
      ].freeze

      TYPES_SCHEMA = [
        { name: 'type_index', type: :int32, optional: false },
        { name: 'type_key', type: :string, optional: true }
      ].freeze

      OBJECT_TYPE_SCHEMA = [
        { name: 'object_index', type: :int32, optional: false },
        { name: 'type_index', type: :int32, optional: false }
      ].freeze

      # eav / type_eav share the value-row shape (keyed by object_index or type_index).
      def self.eav_schema(key_column)
        [
          { name: key_column, type: :int32, optional: false },
          { name: 'path_index', type: :int32, optional: false },
          { name: 'value_string', type: :string, optional: true },
          { name: 'value_double', type: :double, optional: true },
          { name: 'value_boolean', type: :boolean, optional: true },
          { name: 'unit', type: :string, optional: true },
          { name: 'internal_definition_name', type: :string, optional: true }
        ]
      end

      def initialize(output_dir, base_name)
        p = ->(suffix) { File.join(output_dir, "#{base_name}.eav.#{suffix}") }
        @objects = Parquet::ParquetTableWriter.new(p.call('objects.parquet'), OBJECTS_SCHEMA)
        @paths = Parquet::ParquetTableWriter.new(p.call('paths.parquet'), PATHS_SCHEMA)
        @eav = Parquet::ParquetTableWriter.new(p.call('eav.parquet'), EavWriter.eav_schema('object_index'))
        @types = Parquet::ParquetTableWriter.new(p.call('types.parquet'), TYPES_SCHEMA)
        @type_eav = Parquet::ParquetTableWriter.new(p.call('type_eav.parquet'), EavWriter.eav_schema('type_index'))
        @object_type = Parquet::ParquetTableWriter.new(p.call('object_type.parquet'), OBJECT_TYPE_SCHEMA)

        @object_index = IdInterner.new
        @path_index = IdInterner.new
        @type_index = IdInterner.new
        @type_rows_written = {}
        @completed = false
      end

      # Interns an applicationId to its dense object_index (writes the dictionary
      # row on first sight). Public so the envelope path resolves the SAME K.
      def get_or_add_object(application_id)
        is_new, idx = @object_index.get_or_add(application_id)
        @objects.add_row(idx, application_id) if is_new
        idx
      end

      # Appends the flattened rows (EavExtraction::EavRow) for one object.
      def add_rows(application_id, rows)
        object_index = get_or_add_object(application_id)
        rows.each do |row|
          @eav.add_row(
            object_index, get_or_add_path(row.path),
            row.value_text, row.value_num, boolean_value(row), row.unit, row.internal_definition_name
          )
        end
      end

      # Interns a type_key to its dense type_index (writes the dictionary row on
      # first sight). Types are NOT objects: they never touch the objects table.
      def get_or_add_type(type_key)
        is_new, idx = @type_index.get_or_add(type_key)
        @types.add_row(idx, type_key) if is_new
        idx
      end

      # Writes a type's property rows ONCE per type_key, independent of interning
      # order — an `add_object_type` link may have interned the type long before
      # its rows arrive (objects stream during the entity pass, type properties
      # post-loop). Later calls for the same type_key are no-ops.
      def add_type_rows(type_key, rows)
        type_index = get_or_add_type(type_key)
        return type_index if @type_rows_written.key?(type_index)

        @type_rows_written[type_index] = true
        rows.each do |row|
          @type_eav.add_row(
            type_index, get_or_add_path(row.path),
            row.value_text, row.value_num, boolean_value(row), row.unit, row.internal_definition_name
          )
        end
        type_index
      end

      # Links an object to its type (interning both sides) — the star-schema join
      # edge consumers walk as objects -> object_type -> type_eav.
      def add_object_type(application_id, type_key)
        @object_type.add_row(get_or_add_object(application_id), get_or_add_type(type_key))
      end

      def complete
        return if @completed

        @completed = true
        [@objects, @paths, @eav, @types, @type_eav, @object_type].each(&:complete)
      end

      private

      def get_or_add_path(path)
        is_new, idx = @path_index.get_or_add(path)
        @paths.add_row(idx, path) if is_new
        idx
      end

      # value_boolean is non-null only when the row is boolean-typed and its text
      # parses to a bool (mirrors EavWriter.Boolean).
      def boolean_value(row)
        return nil unless row.type == 'boolean'

        case row.value_text.to_s.strip.downcase
        when 'true' then true
        when 'false' then false
        end
      end
    end
  end
end
