# frozen_string_literal: true

require 'delegate'
require_relative 'dictionary_handler'
require_relative '../../constants/dict_constants'

module SpeckleConnector3
  module SketchupModel
    module Dictionary
      # Read and write attributes for Speckle model cards on SketchUp model.
      class ModelCardDictionaryHandler < DictionaryHandler
        # @param send_card [Cards::SendCard] card to save model
        # @param sketchup_model [Sketchup::Model] sketchup model to save cards into it's attribute dictionary
        def self.save_send_card_to_model(send_card, sketchup_model)
          send_cards_dict = send_cards_dict(sketchup_model)
          serialize_obj_to_dict(send_card.model_card_id, send_card, send_cards_dict)
        end

        # @param receive_card [Cards::ReceiveCard] card to save model
        # @param sketchup_model [Sketchup::Model] sketchup model to save cards into it's attribute dictionary
        def self.save_receive_card_to_model(receive_card, sketchup_model)
          receive_cards_dict = receive_cards_dict(sketchup_model)
          serialize_obj_to_dict(receive_card.model_card_id, receive_card, receive_cards_dict)
        end

        # @param obj [Object] object to write
        # @param dict [Sketchup::AttributeDictionary] attribute dictionary to write data.
        def self.serialize_obj_to_dict(dict_name, obj, dict)
          dict_to_write = dict.attribute_dictionary(dict_name, true)

          obj.each do |key, value|
            # value = obj.instance_variable_get(var)
            # var_name = var.to_s[1..-1]
            if value.is_a?(Hash)
              serialize_obj_to_dict(key.to_s, value, dict_to_write)
            else
              dict_to_write[key] = value
            end
          end
        end

        def self.remove_card_dict(sketchup_model, data)
          receive_cards_dict = receive_cards_dict(sketchup_model)
          send_cards_dict = send_cards_dict(sketchup_model)
          if receive_cards_dict && receive_cards_dict.attribute_dictionaries
            receive_cards_dict.attribute_dictionaries.delete(data['modelCardId'])
          end
          if send_cards_dict && send_cards_dict.attribute_dictionaries
            send_cards_dict.attribute_dictionaries.delete(data['modelCardId'])
          end
        end

        def self.get_card_dict(sketchup_model, data)
          send_cards_dict = send_cards_dict(sketchup_model)
          send_cards_dict.attribute_dictionaries.find { |dict| dict.name == data['modelCardId'] }
        end

        def self.get_card_filters_dict(sketchup_model, data)
          card_dict = get_card_dict(sketchup_model, data)
          card_dict.attribute_dictionaries.find { |dict| dict.name == 'filters' }
        end

        def self.get_card_filter_item_dict(sketchup_model, data)
          filters_dict = get_card_filters_dict(sketchup_model, data)
          items_dict = filters_dict.attribute_dictionaries.find { |dict| dict.name == 'items' }
          items_dict.attribute_dictionaries.find { |dict| dict.name == data['filterId'] }
        end

        def self.update_filter(sketchup_model, data, value)
          filter_dict = get_card_filters_dict(sketchup_model, data)
          if filter_dict['multipleSelection']
            filter_dict['selectedItems'] = if value
                                             filter_dict['selectedItems'] + [data['filterId']]
                                           else
                                             filter_dict['selectedItems'] - [data['filterId']]
                                           end
          else
            filter_dict['selectedItems'] = [data['filterId']]
          end
        end

        def self.update_tag_filter(sketchup_model, data, value)
          filter_dict = get_card_filter_item_dict(sketchup_model, data)
          if filter_dict['multipleSelection']
            filter_dict['selectedItems'] = if value
                                             filter_dict['selectedItems'] + [data['tagId']]
                                           else
                                             filter_dict['selectedItems'] - [data['tagId']]
                                           end
          else
            filter_dict['selectedItems'] = [data['tagId']]
          end
        end

        def self.serialize_obj_to_dict_old(dict_name, obj, dict)
          obj.instance_variables.each do |var|
            dict_to_write = dict
            value = obj.instance_variable_get(var)
            var_name = var.to_s[1..-1]
            if value.is_a?(Hash)
              dict_to_write = dict_to_write.attribute_dictionary(dict_name, true)
              dict_to_write = dict_to_write.attribute_dictionary(var_name, true)
              value.each do |key, hash_value|
                serialize_obj_to_dict(key.to_s, hash_value, dict_to_write)
              end
            else
              dict_to_write.set_attribute(dict_name, var_name, value)
            end
          end
        end

        # @param sketchup_model [Sketchup::Model] sketchup model to get send cards.
        # @return [Sketchup::AttributeDictionary, NilClass] attribute dictionary
        def self.send_cards_dict(sketchup_model)
          speckle_dict = sketchup_model.attribute_dictionary('Speckle', true)
          speckle_dict.attribute_dictionary(SPECKLE_SEND_CARDS, true)
        end

        # @param sketchup_model [Sketchup::Model] sketchup model to get receive cards.
        # @return [Sketchup::AttributeDictionary, NilClass] attribute dictionary
        def self.receive_cards_dict(sketchup_model)
          speckle_dict = sketchup_model.attribute_dictionary('Speckle', true)
          speckle_dict.attribute_dictionary(SPECKLE_RECEIVE_CARDS, true)
        end

        def self.get_send_cards_from_dict(sketchup_model)
          send_cards_dict = send_cards_dict(sketchup_model)
          return [] if send_cards_dict.attribute_dictionaries.nil?

          dict_to_h(send_cards_dict)
        end

        def self.get_receive_cards_from_dict(sketchup_model)
          receive_cards_dict = receive_cards_dict(sketchup_model)
          return [] if receive_cards_dict.attribute_dictionaries.nil?

          dict_to_h(receive_cards_dict)
        end

        # @return [String] the name of the dictionary to read from
        def self.dictionary_name
          SPECKLE_SEND_CARDS
        end
      end
    end
  end
end
