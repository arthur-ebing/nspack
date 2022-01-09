# frozen_string_literal: true

module QualityApp
  NewMrlResultSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    optional(:farm_id).maybe(:integer)
    optional(:orchard_id).maybe(:integer)
    optional(:puc_id).maybe(:integer)
    optional(:cultivar_id).filled(:integer)
    optional(:rmt_delivery_id).filled(:integer)
    optional(:production_run_id).filled(:integer)
    required(:season_id).filled(:integer)
    required(:laboratory_id).filled(:integer)
    required(:mrl_sample_type_id).filled(:integer)
    required(:waybill_number).maybe(Types::StrippedString)
    required(:reference_number).maybe(Types::StrippedString)
    required(:sample_number).filled(Types::StrippedString)
    required(:ph_level).maybe(:integer)
    required(:num_active_ingredients).maybe(:integer)
    required(:pre_harvest_result).maybe(:bool)
    required(:post_harvest_result).maybe(:bool)
    required(:fruit_received_at).filled(:time)
    required(:sample_submitted_at).filled(:time)
  end

  MrlResultSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    optional(:farm_id).maybe(:integer)
    optional(:orchard_id).maybe(:integer)
    optional(:puc_id).maybe(:integer)
    optional(:cultivar_id).filled(:integer)
    optional(:rmt_delivery_id).filled(:integer)
    optional(:production_run_id).filled(:integer)
    required(:season_id).filled(:integer)
    required(:laboratory_id).filled(:integer)
    required(:mrl_sample_type_id).filled(:integer)
    required(:waybill_number).maybe(Types::StrippedString)
    required(:reference_number).maybe(Types::StrippedString)
    required(:sample_number).filled(Types::StrippedString)
    required(:ph_level).maybe(:integer)
    required(:num_active_ingredients).maybe(:integer)
    optional(:max_num_chemicals_passed).maybe(:bool)
    optional(:mrl_sample_passed).maybe(:bool)
    required(:pre_harvest_result).maybe(:bool)
    required(:post_harvest_result).maybe(:bool)
    required(:fruit_received_at).filled(:time)
    required(:sample_submitted_at).filled(:time)
    optional(:result_received_at).maybe(:time)
  end

  MrlResultDeliverySchema = Dry::Schema.Params do
    required(:rmt_delivery_id).filled(:integer)
  end

  CaptureMrlResultSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:result_received_at).filled(:time)
    required(:max_num_chemicals_passed).maybe(:bool)
    required(:mrl_sample_passed).maybe(:bool)
  end
end
