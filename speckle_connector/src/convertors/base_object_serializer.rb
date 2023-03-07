# frozen_string_literal: true

# rubocop:disable SketchupPerformance/OpenSSL
require 'securerandom'
# rubocop:enable SketchupPerformance/OpenSSL
require 'digest'
require_relative 'converter'
require_relative '../speckle_entities/speckle_entity'
require_relative '../relations/many_to_one_relation'

module SpeckleConnector
  module Converters
    # Serializer of the base object.
    # Responsible to create id (hash) of the objects by holding their lineage and detaching relationships.
    class BaseObjectSerializer
      # @return [Integer] default chunk size the determine splitting base prop into chucks
      attr_reader :default_chunk_size

      # @return [String] stream id to send conversion
      attr_reader :stream_id

      attr_accessor :speckle_state

      # @param stream_id [String] stream id to send conversion
      def initialize(speckle_state, stream_id, preferences, default_chunk_size = 1000)
        @speckle_state = speckle_state
        @stream_id = stream_id
        @preferences = preferences
        @default_chunk_size = default_chunk_size
        @detach_lineage = []
        @lineage = []
        @family_tree = {}
        @family_tree_relation = Relations::ManyToOneRelation.new
        @closure_table = {}
        @objects = {}
      end

      # @param base [Object] top base object to populate all children and their relationship
      # @return [String, String] id (hash) and traversed hash
      def serialize(base)
        id, traversed = traverse_base(base)
        @objects[id] = traversed
        id
      end

      def total_children_count(id)
        @objects[id][:totalChildrenCount]
      end

      # @param base_and_entities [Object] base object to populate all children and their relationship
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/AbcSize
      def traverse_base(base_and_entities)
        base, entities = base_and_entities

        # 1. Create random string for lineage tracking.
        @lineage.append(SecureRandom.hex)

        # 2. Get last item from detach_lineage array
        is_detached = @detach_lineage.pop

        # unless entities.nil?
        #   is_sent_before = entities.all? do |entity|
        #     check_base_available_on_state(entity, speckle_state)
        #   end
        #   if is_sent_before
        #     speckle_entity = speckle_state.speckle_entities[entities.first.persistent_id]
        #     ref_object = detach_helper(speckle_entity.id)
        #     parent = @lineage[-1]
        #     unless @family_tree[parent].nil?
        #       @family_tree[parent] = @family_tree[parent].merge(speckle_entity.speckle_object[:__closure])
        #     end
        #     @objects[speckle_entity.id] = ref_object if is_detached
        #     return speckle_entity.id, ref_object
        #   end
        # end

        # 3. Initialize traversed base object that will be filled with traversed values or
        # traversed base objects as props.
        traversed_base = SpeckleObjects::Base.new(speckle_type: base[:speckle_type], id: '')

        # 3.1 Remove applicationId if it is nil
        traversed_base.delete(:applicationId)

        # 4. Iterate all entries (key, value) of the base {Base > Hash} object
        # speckle_state = traverse_base_props(base, traversed_base)
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

        # 6. Add total children count
        traversed_base[:totalChildrenCount] = closure.keys.length

        # 7. Finally create id
        id = get_id(traversed_base)

        # 8. Add id to traversed base
        traversed_base[:id] = id

        # 9. Update __closure table on the traversed base
        unless traversed_base[:totalChildrenCount].nil?
          @closure_table[id] = closure
          traversed_base[:__closure] = closure unless closure.empty?
        end

        # 10. Save object string if detached
        @objects[id] = traversed_base if is_detached

        if @preferences[:user][:register_speckle_entity] && !entities.nil?
          entities.uniq.each do |entity|
            speckle_entity = create_or_update_speckle_entity(entity, id, traversed_base)
            @speckle_state = speckle_state.with_speckle_entity(speckle_entity)
          end
        end

        return id, traversed_base
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/AbcSize

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
          prop = prop[2..-1] if is_dynamically_detached

          # 3.4. Check prop needs to split into chunks
          chunked_detach_match = prop.match(/^@\((\d*)\)/)

          # 3.5. If split chunk is needed and prop value is array, then run chunking process
          if value.is_a?(Array) && !base_and_entities?(value) && chunked_detach_match
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

          is_base = (value.is_a?(Hash) && !value[:speckle_type].nil?) ||
                    (base_and_entities?(value) && value[0].is_a?(Hash) && !value[0][:speckle_type].nil?)

          # 3.6. traverse value according to value is a speckle object or not
          traversed_base[prop] = if is_base
                                   is_detach_prop ? detach_helper(child[:id]) : child
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

      # Whether value has a pattern [<converted>, [<entity>, <entity>, ... <entity>]] or not.
      def base_and_entities?(value)
        is_array = value.is_a?(Array)
        return false unless is_array

        return false unless is_array && value.length == 2

        value[1].all? { |v| v.is_a?(Sketchup::Entity) }
      end

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Style/OptionalBooleanParameter
      # rubocop:disable Metrics/AbcSize
      def traverse_value(value, is_detach = false)
        # 1. Return same value if value is primitive type (string, numeric, boolean)
        return value unless value.is_a?(Hash) || value.is_a?(Array)

        # 2. For pure arrays (Without referencing any Sketchup Entity)
        if value.is_a?(Array) && !base_and_entities?(value)

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
            if (el.is_a?(Hash) && !el[:speckle_type].nil?) || base_and_entities?(el)
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

        # 3. Hash
        return value if value.is_a?(Hash) && value[:speckle_type].nil?

        # 4. Base objects
        if (value.is_a?(Hash) && !value[:speckle_type].nil?) || base_and_entities?(value)
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

      # @param traversed_base [SpeckleConnector::SpeckleObjects::Base] traversed base object.
      def get_id(traversed_base)
        Digest::MD5.hexdigest(traversed_base.to_json)
      end

      # rubocop:disable Metrics/MethodLength
      def batch_objects(max_batch_size_mb = 1)
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

      # @param entity [Sketchup::Entity] source entity object
      # @param speckle_state [States::SpeckleState] the current speckle state of the {States::State}
      def check_base_available_on_state(entity, speckle_state)
        is_exist = speckle_state.speckle_entities.keys.include?(entity.persistent_id)
        return is_exist unless is_exist

        speckle_state.speckle_entities[entity.persistent_id].valid_stream_ids.include?(stream_id)
      end

      # Creates or updates speckle entity.
      # If speckle entity exist in state, creates new one by updating old one.
      # Else creates new one
      # @return [SpeckleEntity] speckle entity that collects both speckle and sketchup information.
      def create_or_update_speckle_entity(entity, id, traversed_base)
        if speckle_state.speckle_entities.keys.include?(entity.persistent_id)
          speckle_state.speckle_entities[entity.persistent_id].with_valid_stream_id(stream_id)
        else
          children = traversed_base[:__closure].nil? ? {} : traversed_base[:__closure]
          speckle_entity = SpeckleEntities::SpeckleEntity.new(entity, id, traversed_base[:speckle_type],
                                                              children.keys, [stream_id])
          speckle_entity.write_initial_base_data
          speckle_entity
        end
      end
    end
  end
end
