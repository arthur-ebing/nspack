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

  TripsheetSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    optional(:vehicle_number).maybe(Types::StrippedString)
    required(:planned_location_to_id).filled(:integer)
    required(:business_process_id).filled(:integer)
    required(:stock_type_id).filled(:integer)
    optional(:loaded_at).maybe(:time)
    optional(:offloaded_at).maybe(:time)
    optional(:rmt_delivery_id).maybe(:integer)
    optional(:items_moved_from_job_id).maybe(:integer)
  end

  class TripsheetContract < Dry::Validation::Contract
    params do
      optional(:move_bins).maybe(:bool)
      optional(:from_vehicle_job_id).maybe(:integer)
    end

    rule(:move_bins, :from_vehicle_job_id) do
      base.failure 'Please scan tripsheet' if values[:move_bins] && values[:from_vehicle_job_id].nil_or_empty?
    end
  end
end
