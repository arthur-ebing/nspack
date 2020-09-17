# frozen_string_literal: true

module MesscadaApp
  UpdateRmtBinWeightsSchema = Dry::Schema.Params do
    required(:bin_number).maybe(Types::StrippedString)
    required(:gross_weight).maybe(:decimal)
    required(:measurement_unit).maybe(Types::StrippedString)
  end
end
