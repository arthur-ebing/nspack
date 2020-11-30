# frozen_string_literal: true

module ProductionApp
  BinTippingControlDataSchema = Dry::Schema.Params do
    required(:rmt_product_type).filled(Types::StrippedString)
    required(:treatment_code).filled(Types::StrippedString)
    required(:rmt_size).filled(Types::StrippedString)
    required(:ripe_point_code).filled(Types::StrippedString)
    required(:pc_code).filled(Types::StrippedString)
    required(:product_class_code).filled(Types::StrippedString)
    required(:track_indicator_code).filled(Types::StrippedString)
  end
end
