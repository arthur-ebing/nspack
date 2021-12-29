# frozen_string_literal: true

module ProductionApp
  BinTippingControlDataSchema = Dry::Schema.Params do
    optional(:colour_percentage_id).maybe(:integer)
    optional(:actual_cold_treatment_id).maybe(:integer)
    optional(:actual_ripeness_treatment_id).maybe(:integer)
    optional(:rmt_code_id).maybe(:integer)
    optional(:rmt_size_id).maybe(:integer)
    optional(:rmt_class_id).maybe(:integer)
  end
end
