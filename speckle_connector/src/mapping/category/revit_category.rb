# frozen_string_literal: true

module SpeckleConnector
  module Mapping
    module Category
      # Revit categories.
      class RevitCategory < Hash
        class << self
          # rubocop:disable Metrics/MethodLength
          def dictionary
            {
              AbutmentFoundations: 0,
              AbutmentPiles: 1,
              AbutmentWalls: 2,
              BridgeAbutments: 3,
              DuctTerminal: 4,
              Alignments: 5,
              StructConnectionAnchors: 6,
              ApproachSlabs: 7,
              BridgeArches: 8,
              AudioVisualDevices: 9,
              StairsRailingBaluster: 10,
              BridgeBearings: 11,
              StructConnectionBolts: 12,
              BridgeCables: 13,
              BridgeDecks: 14,
              BridgeFraming: 15,
              CableTrayFitting: 16,
              CableTrayRun: 17,
              CableTray: 18,
              Casework: 19,
              Ceilings: 20,
              Columns: 21,
              CommunicationDevices: 22,
              ConduitFitting: 23,
              Conduit: 24,
              Coordination_Model: 25,
              BridgeFramingCrossBracing: 26,
              CurtainWallPanels: 27,
              CurtaSystem: 28,
              CurtainWallMullions: 29,
              DataDevices: 30,
              BridgeFramingDiaphragms: 31,
              Doors: 32,
              DuctAccessory: 33,
              DuctFitting: 34,
              PlaceHolderDucts: 35,
              DuctSystem: 36,
              DuctCurves: 37,
              ElectricalEquipment: 38,
              ElectricalFixtures: 39,
              Entourage: 40,
              ExpansionJoints: 41,
              FireAlarmDevices: 42,
              FireProtection: 43,
              Floors: 44,
              FoodServiceEquipment: 45,
              Furniture: 46,
              FurnitureSystems: 47,
              GenericAnnotation: 48,
              GenericModel: 49,
              BridgeGirders: 50,
              Hardscape: 51,
              LightingDevices: 52,
              LightingFixtures: 53,
              Lines: 54,
              Mass: 55,
              MechanicalEquipment: 56,
              MedicalEquipment: 57,
              NurseCallDevices: 58,
              Parking: 59,
              Parts: 60,
              PierCaps: 61,
              PierColumns: 62,
              BridgeFoundations: 63,
              PierPiles: 64,
              BridgeTowers: 65,
              PierWalls: 66,
              BridgePiers: 67,
              PipeAccessory: 68,
              PipeFitting: 69,
              PlaceHolderPipes: 70,
              PipeSegments: 71,
              PipeCurves: 72,
              PipingSystem: 73,
              Planting: 74,
              StructConnectionPlates: 75,
              PlumbingFixtures: 76,
              StructConnectionProfiles: 77,
              StairsRailing: 78,
              Ramps: 79,
              Roads: 80,
              Roofs: 81,
              SecurityDevices: 82,
              StructConnectionShearStuds: 83,
              Signage: 84,
              Site: 85,
              SpecialityEquipment: 86,
              Sprinklers: 87,
              Stairs: 88,
              StructuralFramingSystem: 89,
              StructuralColumns: 90,
              StructConnections: 91,
              FabricAreas: 92,
              StructuralFoundation: 93,
              StructuralFraming: 94,
              Rebar: 95,
              Coupler: 96,
              StructuralStiffener: 97,
              StructuralTendons: 98,
              StructuralTruss: 99,
              TemporaryStructure: 100,
              Topography: 101,
              BridgeFramingTrusses: 102,
              VerticalCirculation: 103,
              VibrationDampers: 104,
              VibrationIsolators: 105,
              VibrationManagement: 106,
              Walls: 107,
              StructConnectionWelds: 108,
              Windows: 109
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
