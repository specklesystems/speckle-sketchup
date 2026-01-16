# frozen_string_literal: true

# rubocop:disable SketchupPerformance/OpenSSL
require 'securerandom'
# rubocop:enable SketchupPerformance/OpenSSL
require 'digest'
require_relative 'converter'
require_relative '../speckle_objects/base'
require_relative '../speckle_objects/object_reference'
require_relative '../speckle_entities/speckle_entity'
require_relative '../relations/many_to_one_relation'

module SpeckleConnector3
  module Converters
    # Serializer of the base object.
    # Responsible to create id (hash) of the objects by holding their lineage and detaching relationships.
    class BaseObjectSerializer
      # @return [Integer] default chunk size the determine splitting base prop into chucks
      attr_reader :default_chunk_size

      attr_reader :object_references

      def initialize(preferences, default_chunk_size = 1000)
        @preferences = preferences
        @default_chunk_size = default_chunk_size
        @detach_lineage = []
        @lineage = []
        @family_tree = {}
        @closure_table = {}
        @objects = {}
        @object_references = {}
      end

      # @param base [Object] top base object to populate all children and their relationship
      # @return [String, String] id (hash) and traversed hash
      def serialize(base)
        id, traversed = traverse_base(base)
        @objects[id] = traversed
        id
      end

      # @param base [Object] base object to populate all children and their relationship
      # rubocop:disable Metrics/MethodLength
      def traverse_base(base)
        # 1. Create random string for lineage tracking.
        @lineage.append(SecureRandom.hex)

        # 2. Get last item from detach_lineage array
        is_detached = @detach_lineage.pop

        # 3. Initialize traversed base object that will be filled with traversed values or
        # traversed base objects as props.
        traversed_base = SpeckleObjects::Base.new(speckle_type: base[:speckle_type], id: '')

        # 3.1 Remove applicationId if it is nil
        traversed_base.delete(:applicationId)

        # 4. Iterate all entries (key, value) of the base {Base > Hash} object
        traverse_base_props(base, traversed_base)
        # this is where all props are done for current `traversed_base`

        # 5. Add closures
        closure = {}
        parent = @lineage.pop
        unless @family_tree[parent].nil?
          @family_tree[parent].each do |ref, depth|
            closure[ref] = depth - @detach_lineage.length
          end
        end

        # 7. Finally create id
        id = get_id(traversed_base)

        # 8. Add id to traversed base
        traversed_base[:id] = id

        # 9. Update __closure table on the traversed base
        unless closure.empty?
          @closure_table[id] = closure
          traversed_base[:__closure] = closure unless closure.empty?
        end

        # 10. Save object string if detached
        @objects[id] = traversed_base if is_detached

        if traversed_base[:applicationId]
          @object_references[traversed_base[:applicationId].to_s] = SpeckleObjects::ObjectReference.new(
            id, traversed_base[:applicationId].to_s, traversed_base[:__closure]
          )
        end

        return id, traversed_base
      end
      # rubocop:enable Metrics/MethodLength

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/BlockLength
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def traverse_base_props(base, traversed_base)
        base.each do |prop, value|
          # 3.1. Ignore nil, starts with '_' and 'id'
          next if value.nil? || prop[0] == '_' || prop == 'id' || prop == :id

          # 3.2. Pass primitives without any operation (string, numeric, boolean)
          unless value.is_a?(Hash) || value.is_a?(Array)
            traversed_base[prop] = value
            next
          end

          # 3.3. Determine prop is dynamically detached or not
          is_detach_prop = prop[0] == '@'
          is_dynamically_detached = prop[0] == '@' && prop.length > 2 && prop[1] == '@'
          if is_dynamically_detached
            prop = prop[2..-1]
          else
            prop = prop[1..-1] if is_detach_prop
          end

          # 3.4. Check prop needs to split into chunks
          chunked_detach_match = prop.match(/^@\((\d*)\)/)

          # 3.5. If split chunk is needed and prop value is array, then run chunking process
          if value.is_a?(Array) && chunked_detach_match
            # 3.5.1. Determine chunk size, get it from prop if defined. ex: '@(31250)faces' -> 31250 = chunk size
            chunk_size = chunked_detach_match[1] == '' ? default_chunk_size : chunked_detach_match[1].to_i

            # 3.5.2. Init empty array for chunks
            chunks = []

            # 3.5.3. Init empty data chunk core object
            chunk = {
              speckle_type: 'Speckle.Core.Models.DataChunk',
              data: []
            }

            # 3.5.4. Iterate each element on array to fill them into chunks
            value.each_with_index do |el, index|
              # 3.5.4.1. If current index is the multiplier of the chunk size, then need to append chunk into chunks
              # and reinitialize empty chunk for next batch
              if (index % chunk_size == 0) && index != 0
                chunks.append(chunk)
                chunk = {
                  speckle_type: 'Speckle.Core.Models.DataChunk',
                  data: []
                }
              end
              # 3.5.4.2. Add element into chunk
              chunk[:data].append(el)
            end

            # 3.5.5. Add trailing batch to the chunks also unless is empty
            chunks.append(chunk) unless chunk[:data].empty?

            # 3.5.6. Initialize empty chunk reference array
            chunk_references = []

            chunks.each do |chunk_element|
              @detach_lineage.append(is_detach_prop)
              id, _traversed = traverse_base(chunk_element)
              chunk_references.append(detach_helper(id))
            end

            # 3.5.7. Add chunk references to the traversed base prop without @(<chunk_size>)
            traversed_base[prop.to_s.sub(chunked_detach_match[0], '')] = chunk_references

            # 3.5.8. We are done chunking, good to go next property
            next
          end

          child = traverse_value(value, is_detach_prop)

          is_base = value.is_a?(Hash) && !value[:speckle_type].nil?

          # 3.6. traverse value according to value is a speckle object or not
          traversed_base[prop] = if is_base
                                   if child[:referencedId] && child[:speckle_type] == 'reference'
                                     is_detach_prop ? detach_helper(child[:referencedId]) : child
                                   else
                                     is_detach_prop ? detach_helper(child[:id]) : child
                                   end
                                 else
                                   child
                                 end
        end
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/BlockLength
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Style/OptionalBooleanParameter
      # rubocop:disable Metrics/AbcSize
      def traverse_value(value, is_detach = false)
        # 1. Return same value if value is primitive type (string, numeric, boolean)
        return value unless value.is_a?(Hash) || value.is_a?(Array)

        # 2. For pure arrays
        if value.is_a?(Array)

          # 2.1. If it is not detached then iterate array by traversing with their value
          unless is_detach
            values = value.collect do |el|
              el_value = traverse_value(el)
              el_value
            end
            return values
          end

          # 2.2. If it is detached than collect them into detached_list
          detached_list = []
          value.each do |el|
            if el.is_a?(SpeckleObjects::ObjectReference)
              if el.closure
                el.closure.each_key do |k|
                  detach_helper(k)
                end
              end
              detached_list.append(detach_helper(el.referenced_id))
              next
            end

            if el.is_a?(Hash) && !el[:speckle_type].nil?
              @detach_lineage.append(is_detach)
              id, _traversed_base = traverse_base(el)
              detached_list.append(detach_helper(id))
            else
              el_value = traverse_value(el, is_detach)
              detached_list.append(el_value)
            end
          end
          return detached_list
        end

        # 3. ObjectReference
        if value.is_a?(SpeckleObjects::ObjectReference)
          if value.closure
            value.closure.each_key do |k|
              detach_helper(k)
            end
          end
          return detach_helper(value.referenced_id)
        end

        # 4. Hash
        return value if value.is_a?(Hash) && value[:speckle_type].nil?

        # 5. Base objects
        if value.is_a?(Hash) && !value[:speckle_type].nil?
          @detach_lineage.append(is_detach)
          _id, traversed_base = traverse_base(value)
          return traversed_base
        end

        # 5. If it is not returned until here then there is unsupported type
        raise StandardError "Unsupported type #{value.class} : #{value}"
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Style/OptionalBooleanParameter
      # rubocop:enable Metrics/AbcSize

      def detach_helper(reference_id)
        @lineage.each do |parent|
          # init parent on the family tree unless exist
          @family_tree[parent] = {} if @family_tree[parent].nil?

          is_ref_exist = !@family_tree[parent].nil? && !@family_tree[parent][reference_id].nil?

          if !is_ref_exist || @family_tree[parent][reference_id] > @detach_lineage.length
            @family_tree[parent][reference_id] = @detach_lineage.length
          end
        end
        {
          referencedId: reference_id,
          speckle_type: 'reference'
        }
      end

      # @param traversed_base [SpeckleConnector3::SpeckleObjects::Base] traversed base object.
      def get_id(traversed_base)
        Digest::MD5.hexdigest(traversed_base.to_json)
      end

      def batch_objects
        @objects
      end

      # rubocop:disable Metrics/MethodLength
      def batch_json_objects(max_batch_size_mb = 1)
        max_size = 1000 * 1000 * max_batch_size_mb
        batches = []
        batch = '['
        batch_size = 0
        objects = @objects.values
        objects.each do |obj|
          obj_json = obj.to_json
          if batch_size + obj_json.length < max_size
            batch += obj_json
            batch += ','
            batch_size += obj_json.length
          else
            batch = batch.chop
            batches.append("#{batch}]")
            batch = "[#{obj_json},"
            batch_size = obj_json.length
          end
        end
        batch = batch.chop
        batches.append("#{batch}]")
        batches
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
