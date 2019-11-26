# frozen_string_literal: true

module FinishedGoodsApp
  LoadVehicleSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:load_id, :integer).filled(:int?)
    required(:vehicle_type_id, :integer).filled(:int?)
    required(:haulier_party_role_id, :integer).filled(:int?)
    required(:vehicle_number, Types::StrippedString).filled(:str?)
    optional(:vehicle_weight_out, %i[nil decimal]).maybe(:decimal?)
    optional(:dispatch_consignment_note_number, Types::StrippedString).maybe(:str?)
    optional(:vehicle_id, :integer).filled(:int?)
    required(:driver_name, Types::StrippedString).maybe(:str?)
    required(:driver_cell_number, Types::StrippedString).maybe(:str?)
  end
end
