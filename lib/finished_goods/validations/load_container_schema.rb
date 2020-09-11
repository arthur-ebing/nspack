# frozen_string_literal: true

module FinishedGoodsApp
  LoadContainerSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    optional(:load_container_id).maybe(:integer)
    required(:load_id).filled(:integer)
    required(:container_code).filled(Types::StrippedString, max_size?: 13)
    required(:container_vents).maybe(Types::StrippedString)
    required(:container_seal_code).maybe(Types::StrippedString)
    required(:container_temperature_rhine).maybe(Types::StrippedString)
    required(:container_temperature_rhine2).maybe(Types::StrippedString)
    optional(:internal_container_code).maybe(Types::StrippedString)
    required(:max_gross_weight).filled(:decimal)
    optional(:verified_gross_weight).filled(:decimal)
    optional(:verified_gross_weight_date).filled(:time)
    required(:cargo_temperature_id).filled(:integer)
    required(:stack_type_id).filled(:integer)
    optional(:actual_payload).maybe(:decimal)
    if AppConst::VGM_REQUIRED
      required(:tare_weight).filled(:decimal)
      required(:max_payload).filled(:decimal)
    else
      optional(:tare_weight).maybe(:decimal)
      optional(:max_payload).maybe(:decimal)
    end
  end
end
