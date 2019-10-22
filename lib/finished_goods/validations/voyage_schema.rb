# frozen_string_literal: true

module FinishedGoodsApp
  VoyageSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:vessel_id, :integer).filled(:int?)
    required(:voyage_type_id, :integer).filled(:int?)
    required(:voyage_number, Types::StrippedString).filled(:str?)
    optional(:voyage_code, Types::StrippedString).maybe(:str?)
    required(:year, :integer).filled(:int?)
    optional(:completed, :bool).maybe(:bool?)
    optional(:completed_at, :time).filled(:time?)
  end
end
