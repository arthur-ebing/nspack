# frozen_string_literal: true

module FinishedGoodsApp
  LoadVehicleSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    optional(:load_vehicle_id).maybe(:integer)
    required(:load_id).filled(:integer)
    required(:vehicle_type_id).filled(:integer)
    required(:haulier_party_role_id).filled(:integer)
    required(:vehicle_number).filled(Types::StrippedString)
    optional(:vehicle_weight_out).maybe(:decimal)
    optional(:dispatch_consignment_note_number).maybe(Types::StrippedString)
    required(:driver_name).filled(Types::StrippedString)
    required(:driver_cell_number).filled(Types::StrippedString)
  end
end
