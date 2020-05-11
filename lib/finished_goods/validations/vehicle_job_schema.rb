# frozen_string_literal: true

module FinishedGoodsApp
  VehicleJobSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    optional(:vehicle_number, Types::StrippedString).maybe(:str?)
    required(:govt_inspection_sheet_id, :integer).filled(:int?)
    required(:planned_location_to_id, :integer).filled(:int?)
    required(:business_process_id, :integer).filled(:int?)
    required(:stock_type_id, :integer).filled(:int?)
    optional(:loaded_at, %i[nil time]).maybe(:time?)
    optional(:offloaded_at, %i[nil time]).maybe(:time?)
  end
end
