# frozen_string_literal: true

module QualityApp
  QcTestSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:qc_measurement_type_id).filled(:integer)
    required(:qc_sample_id).filled(:integer)
    required(:qc_test_type_id).filled(:integer)
    required(:instrument_plant_resource_id).maybe(:integer)
    required(:sample_size).filled(:integer)
    required(:editing).maybe(:bool)
    required(:completed).maybe(:bool)
    required(:completed_at).maybe(:time)
  end
end
