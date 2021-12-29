# frozen_string_literal: true

module ProductionApp
  BinTippingControlDataSchema = Dry::Schema.Params do
    required(:colour_percentage_id).filled(:integer)
    required(:actual_cold_treatment_id).filled(:integer)
    required(:actual_ripeness_treatment_id).filled(:integer)
    required(:rmt_code_id).filled(:integer)
    required(:rmt_size_id).filled(:integer)
  end
end
