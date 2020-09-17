# frozen_string_literal: true

module FinishedGoodsApp
  LoadVoyageSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:load_id).filled(:integer)
    required(:voyage_id).filled(:integer)
    optional(:shipping_line_party_role_id).maybe(:integer)
    optional(:shipper_party_role_id).maybe(:integer)
    optional(:booking_reference).maybe(Types::StrippedString)
    optional(:memo_pad).maybe(Types::StrippedString)
  end
end
