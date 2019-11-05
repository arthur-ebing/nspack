# frozen_string_literal: true

module FinishedGoodsApp
  LoadContainerSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:load_id, :integer).filled(:int?)
    required(:container_code, Types::StrippedString).filled(:str?)
    required(:container_vents, Types::StrippedString).maybe(:str?)
    required(:container_seal_code, Types::StrippedString).maybe(:str?)
    required(:container_temperature_rhine, %i[nil decimal]).filled(:decimal?)
    required(:container_temperature_rhine2, %i[nil decimal]).maybe(:decimal?)
    optional(:internal_container_code, Types::StrippedString).maybe(:str?)
    required(:max_gross_weight, %i[nil decimal]).filled(:decimal?)
    optional(:tare_weight, %i[nil decimal]).maybe(:decimal?)
    optional(:max_payload, %i[nil decimal]).maybe(:decimal?)
    optional(:actual_payload, %i[nil decimal]).maybe(:decimal?)
    required(:verified_gross_weight, %i[nil decimal]).filled(:decimal?)
    required(:verified_gross_weight_date, %i[nil time]).filled(:time?)
    required(:cargo_temperature_id, :integer).filled(:int?)
    required(:stack_type_id, :integer).filled(:int?)
  end

  VGM_REQUIRED_Schema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:load_id, :integer).filled(:int?)
    required(:container_code, Types::StrippedString).filled(:str?)
    required(:container_vents, Types::StrippedString).maybe(:str?)
    required(:container_seal_code, Types::StrippedString).maybe(:str?)
    required(:container_temperature_rhine, %i[nil decimal]).filled(:decimal?)
    required(:container_temperature_rhine2, %i[nil decimal]).maybe(:decimal?)
    optional(:internal_container_code, Types::StrippedString).maybe(:str?)
    required(:max_gross_weight, %i[nil decimal]).filled(:decimal?)
    required(:tare_weight, %i[nil decimal]).filled(:decimal?)
    required(:max_payload, %i[nil decimal]).filled(:decimal?)
    required(:actual_payload, %i[nil decimal]).filled(:decimal?)
    required(:verified_gross_weight, %i[nil decimal]).filled(:decimal?)
    required(:verified_gross_weight_date, %i[nil time]).filled(:time?)
    required(:cargo_temperature_id, :integer).filled(:int?)
    required(:stack_type_id, :integer).filled(:int?)
  end
end
