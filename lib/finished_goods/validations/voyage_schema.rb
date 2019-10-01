# frozen_string_literal: true

module FinishedGoodsApp
  VoyageSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:vessel_id, :integer).filled(:int?)
    required(:voyage_type_id, :integer).filled(:int?)
    optional(:voyage_number, Types::StrippedString).filled(:str?)
    optional(:voyage_code, Types::StrippedString).filled(:str?)
    required(:year, :integer).maybe(:int?)
    optional(:completed, :bool).maybe(:bool?)
    optional(:completed_at, :time).maybe(:time?)
  end
end
