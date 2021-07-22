# frozen_string_literal: true

module RawMaterialsApp
  PresortStagingRunSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    optional(:uncompleted_at).maybe(:time)
    optional(:completed).maybe(:bool)
    required(:presort_unit_plant_resource_id).filled(:integer)
    required(:supplier_id).filled(:integer)
    optional(:completed_at).maybe(:time)
    optional(:canceled).maybe(:bool)
    optional(:canceled_at).maybe(:time)
    required(:cultivar_id).filled(:integer)
    required(:rmt_class_id).filled(:integer)
    required(:rmt_size_id).filled(:integer)
    required(:season_id).filled(:integer)
    optional(:editing).maybe(:bool)
    optional(:staged).maybe(:bool)
    optional(:active).maybe(:bool)
    optional(:legacy_data).maybe(:hash)
  end
end
