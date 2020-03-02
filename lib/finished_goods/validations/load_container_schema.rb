# frozen_string_literal: true

module FinishedGoodsApp
  LoadContainerSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:load_id, :integer).filled(:int?)
    required(:container_code, Types::StrippedString).filled(:str?, max_size?: 11)
    required(:container_vents, Types::StrippedString).maybe(:str?)
    required(:container_seal_code, Types::StrippedString).maybe(:str?)
    required(:container_temperature_rhine, Types::StrippedString).maybe(:str?)
    required(:container_temperature_rhine2, Types::StrippedString).maybe(:str?)
    optional(:internal_container_code, Types::StrippedString).maybe(:str?)
    required(:max_gross_weight, %i[nil decimal]).filled(:decimal?)
    optional(:verified_gross_weight, %i[nil decimal]).filled(:decimal?)
    optional(:verified_gross_weight_date, %i[nil time]).filled(:time?)
    required(:cargo_temperature_id, :integer).filled(:int?)
    required(:stack_type_id, :integer).filled(:int?)
    optional(:container_id, :integer).filled(:int?)
    if AppConst::VGM_REQUIRED
      required(:tare_weight, %i[nil decimal]).filled(:decimal?)
      required(:max_payload, %i[nil decimal]).filled(:decimal?)
      required(:actual_payload, %i[nil decimal]).filled(:decimal?)
    else
      optional(:tare_weight, %i[nil decimal]).maybe(:decimal?)
      optional(:max_payload, %i[nil decimal]).maybe(:decimal?)
      optional(:actual_payload, %i[nil decimal]).maybe(:decimal?)
    end
  end
end
