# frozen_string_literal: true

module FinishedGoodsApp
  VehicleJobUnitSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:vehicle_job_id).filled(:integer)
    required(:stock_type_id).filled(:integer)
    required(:stock_item_id).filled(:integer)
    optional(:loaded_at).maybe(:time)
    optional(:offloaded_at).maybe(:time)
  end
end
