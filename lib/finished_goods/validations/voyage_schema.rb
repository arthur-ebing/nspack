# frozen_string_literal: true

module FinishedGoodsApp
  VoyageSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:vessel_id).filled(:integer)
    required(:voyage_type_id).filled(:integer)
    required(:voyage_number).filled(Types::StrippedString)
    optional(:voyage_code).maybe(Types::StrippedString)
    required(:year).filled(:integer)
    optional(:completed).maybe(:bool)
    optional(:completed_at).filled(:time)
  end
  UpdateVoyageSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:vessel_id).filled(:integer)
    optional(:voyage_type_id).maybe(:integer)
    required(:voyage_number).filled(Types::StrippedString)
    optional(:voyage_code).maybe(Types::StrippedString)
    required(:year).filled(:integer)
    optional(:completed).maybe(:bool)
    optional(:completed_at).filled(:time)
  end
end
