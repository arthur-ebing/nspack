# frozen_string_literal: true

module MesscadaApp
  CartonLabelingSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:device, Types::StrippedString).filled(:str?)
  end

  CartonVerificationSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:carton_number, :integer).filled(:int?)
    required(:device, Types::StrippedString).filled(:str?)
  end

  CartonVerificationAndWeighingSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:carton_number, :integer).filled(:int?)
    required(:device, Types::StrippedString).filled(:str?)
    required(:gross_weight, :decimal).filled(:decimal?)
    required(:measurement_unit, Types::StrippedString).filled(:str?)
  end
end
