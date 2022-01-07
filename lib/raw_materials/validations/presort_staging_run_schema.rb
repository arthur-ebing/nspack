# frozen_string_literal: true

module RawMaterialsApp
  PresortStagingRunSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    optional(:uncompleted_at).maybe(:time)
    optional(:completed).maybe(:bool)
    required(:presort_unit_plant_resource_id).filled(:integer)
    optional(:supplier_id).maybe(:integer)
    optional(:completed_at).maybe(:time)
    optional(:canceled).maybe(:bool)
    optional(:canceled_at).maybe(:time)
    required(:cultivar_id).filled(:integer)
    optional(:rmt_class_id).maybe(:integer)
    optional(:rmt_size_id).maybe(:integer)
    required(:season_id).filled(:integer)
    optional(:editing).maybe(:bool)
    optional(:staged).maybe(:bool)
    optional(:running).maybe(:bool)
    optional(:legacy_data).maybe(:hash)
    optional(:colour_percentage_id).maybe(:integer)
    optional(:actual_cold_treatment_id).maybe(:integer)
    optional(:actual_ripeness_treatment_id).maybe(:integer)
    optional(:rmt_code_id).maybe(:integer)
  end
end
