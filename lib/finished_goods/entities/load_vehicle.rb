# frozen_string_literal: true

module FinishedGoodsApp
  class LoadVehicle < Dry::Struct
    attribute :id, Types::Integer
    attribute :load_id, Types::Integer
    attribute :vehicle_type_id, Types::Integer
    attribute :haulier_party_role_id, Types::Integer
    attribute :vehicle_number, Types::String
    attribute :vehicle_weight_out, Types::Decimal
    attribute :dispatch_consignment_note_number, Types::String
    attribute :driver_name, Types::String
    attribute :driver_cell_number, Types::String
    attribute? :active, Types::Bool
  end

  class LoadVehicleFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :load_vehicle_id, Types::Integer
    attribute :load_id, Types::Integer
    attribute :vehicle_type_id, Types::Integer
    attribute :vehicle_type_code, Types::String
    attribute :haulier_party_role_id, Types::Integer
    attribute :haulier, Types::String
    attribute :vehicle_number, Types::String
    attribute :vehicle_weight_out, Types::Decimal
    attribute :dispatch_consignment_note_number, Types::String
    attribute :driver_name, Types::String
    attribute :driver_cell_number, Types::String
    attribute? :active, Types::Bool
  end
end
