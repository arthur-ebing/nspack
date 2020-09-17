# frozen_string_literal: true

module FinishedGoodsApp
  VehicleJobSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    optional(:vehicle_number).maybe(Types::StrippedString)
    required(:govt_inspection_sheet_id).filled(:integer)
    required(:planned_location_to_id).filled(:integer)
    required(:business_process_id).filled(:integer)
    required(:stock_type_id).filled(:integer)
    optional(:loaded_at).maybe(:time)
    optional(:offloaded_at).maybe(:time)
  end
end
