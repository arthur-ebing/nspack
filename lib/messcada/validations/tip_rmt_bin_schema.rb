# frozen_string_literal: true

module MesscadaApp
  TipRmtBinSchema = Dry::Schema.Params do
    required(:bin_number).maybe(Types::StrippedString)
    required(:device).maybe(Types::StrippedString)
  end
end
