# frozen_string_literal: true

require 'json'

require_relative '../action'
require_relative '../../convertors/units'
require_relative '../../convertors/to_native'

module SpeckleConnector
  module Actions
    # Clear mappings for selected entities.
    class ReceiveSingleObject < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, stream_id, root_id, speckle_objects)
        puts "object receive #{speckle_objects.length}"
        buffer = speckle_objects.collect { |obj| [obj['id'], obj] }.to_h
        t_0 = Time.now.to_f
        root_obj = traverse_and_construct(speckle_objects.first, buffer)
        puts root_obj
        puts "Elapsed traverse and construct #{Time.now.to_f - t_0}"

        # File.open("#{ENV['HOME']}/OneDrive/Masaüstü/root.json", 'w') do |f|
        #   f.write(JSON.pretty_generate(root_obj))
        # end

        # converter = Converters::ToNative.new(state, stream_id, 'test', 'testt', 'test')
        # state = converter.receive_commit_object(root_obj)

        js_script = "sketchupReceiveBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('receiveObject', js_script)
      end

      def self.traverse_and_construct(obj, buffer)
        return if obj.nil?
        return obj if !obj.is_a?(Hash) && !obj.is_a?(Array)

        # Handle arrays
        if obj.is_a?(Array) && !obj.empty?
          arr = handle_array(buffer, obj)

          # De-chunk, if array is a set of datachunk, flat them into single data chunk.
          arr = try_dechunk(arr)

          return arr
        end

        # Handle object
        obj = handle_hash(buffer, obj)

        return obj
      rescue StandardError => e
        puts "#{e} -> #{obj}"
        return nil
      end

      def self.handle_array(buffer, obj)
        arr = []
        obj.collect do |element|
          next if element.nil?

          deref = element.is_a?(Hash) && !element['referencedId'].nil? ? buffer[element['referencedId']] : element
          arr.append(traverse_and_construct(deref, buffer))
        end
        arr
      end

      def self.try_dechunk(arr)
        if arr[0].is_a?(Hash) && !arr[0]['speckle_type'].nil? && arr[0]['speckle_type'].downcase.include?('datachunk')
          sum_arr = []
          arr.each do |chunk|
            sum_arr += chunk['data']
          end
          sum_arr
        else
          arr
        end
      end

      def self.handle_hash(buffer, obj)
        obj.each do |prop, value|
          next if value.nil? || (!value.is_a?(Hash) && !value.is_a?(Array))

          obj[prop] = buffer[value['referencedId']] if value.is_a?(Hash) && value['referencedId']
          obj[prop] = traverse_and_construct(obj[prop], buffer)
        end
        obj
      end
    end
  end
end
