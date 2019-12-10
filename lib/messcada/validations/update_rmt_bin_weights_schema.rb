# frozen_string_literal: true

module MesscadaApp
  UpdateRmtBinWeightsSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:bin_number, Types::StrippedString).maybe(:str?)
    required(:gross_weight, :decimal).maybe(:decimal?)
    required(:measurement_unit, Types::StrippedString).maybe(:str?)
  end
end
