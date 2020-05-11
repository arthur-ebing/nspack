# frozen_string_literal: true

module FinishedGoodsApp
  VehicleJobUnitSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:vehicle_job_id, :integer).filled(:int?)
    required(:stock_type_id, :integer).filled(:int?)
    required(:stock_item_id, :integer).filled(:int?)
    optional(:loaded_at, %i[nil time]).maybe(:time?)
    optional(:offloaded_at, %i[nil time]).maybe(:time?)
  end
end
