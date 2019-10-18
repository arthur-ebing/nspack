# frozen_string_literal: true

module FinishedGoodsApp
  LoadVoyageSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:load_id, :integer).filled(:int?)
    required(:voyage_id, :integer).filled(:int?)
    optional(:shipping_line_party_role_id, :integer).maybe(:int?)
    optional(:shipper_party_role_id, :integer).maybe(:int?)
    optional(:booking_reference, Types::StrippedString).maybe(:str?)
    optional(:memo_pad, Types::StrippedString).maybe(:str?)
  end
end
