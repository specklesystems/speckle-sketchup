# frozen_string_literal: true

module SpeckleConnector3
  module Mapper
    module Category
      # Revit categories for families.
      class RevitFamilyCategory < Hash
        class << self
          # rubocop:disable Metrics/MethodLength
          def dictionary
            {
              AudioVisualDevices: 9,
              CableTrayFitting: 16,
              Casework: 19,
              Columns: 21,
              CommunicationDevices: 22,
              ConduitFitting: 23,
              DataDevices: 30,
              Doors: 32,
              DuctAccessory: 33,
              ElectricalEquipment: 38,
              ElectricalFixtures: 39,
              Entourage: 40,
              FireAlarmDevices: 42,
              FireProtection: 43,
              FoodServiceEquipment: 45,
              Furniture: 46,
              FurnitureSystems: 47,
              GenericAnnotation: 48,
              GenericModel: 49,
              Hardscape: 51,
              LightingDevices: 52,
              LightingFixtures: 53,
              Lines: 54,
              Mass: 55,
              MechanicalEquipment: 56,
              MedicalEquipment: 57,
              NurseCallDevices: 58,
              Parking: 59,
              PipeAccessory: 68,
              PipeFitting: 69,
              Planting: 74,
              PlumbingFixtures: 76,
              Roads: 80,
              SecurityDevices: 82,
              Signage: 84,
              Site: 85,
              SpecialityEquipment: 86,
              Sprinklers: 87,
              StructuralFramingSystem: 89,
              StructuralColumns: 90,
              StructConnections: 91,
              StructuralFoundation: 93,
              StructuralFraming: 94,
              StructuralStiffener: 97,
              TemporaryStructure: 100,
              VerticalCirculation: 103,
              Windows: 109,
              Railings: 110
            }.freeze
          end
          # rubocop:enable Metrics/MethodLength

          def reverse_dictionary
            dictionary.collect { |k, v| [v, k] }.to_h
          end

          def to_a
            dictionary.collect { |k, v| { key: k, value: v } }.to_a
          end

          def reverse_to_a
            dictionary.collect { |k, v| { key: v, value: k } }.to_a
          end
        end
      end
    end
  end
end
