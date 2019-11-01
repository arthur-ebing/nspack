# frozen_string_literal: true

module FinishedGoodsApp
  LoadContainerSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:load_id, :integer).filled(:int?)
    required(:container_code, Types::StrippedString).filled(:str?)
    required(:container_vents, Types::StrippedString).maybe(:str?)
    required(:container_seal_code, Types::StrippedString).filled(:str?)
    required(:container_temperature_rhine, %i[nil decimal]).maybe(:decimal?)
    required(:container_temperature_rhine2, %i[nil decimal]).maybe(:decimal?)
    required(:internal_container_code, Types::StrippedString).filled(:str?)
    required(:max_gross_weight, %i[nil decimal]).maybe(:decimal?)
    required(:tare_weight, %i[nil decimal]).maybe(:decimal?)
    required(:max_payload, %i[nil decimal]).maybe(:decimal?)
    required(:actual_payload, %i[nil decimal]).maybe(:decimal?)
    required(:verified_gross_weight, %i[nil decimal]).maybe(:decimal?)
    required(:verified_gross_weight_date, %i[nil time]).maybe(:time?)
    required(:cargo_temperature_id, :integer).filled(:int?)
    required(:stack_type_id, :integer).filled(:int?)
  end
end
