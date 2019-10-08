# frozen_string_literal: true

module MesscadaApp
  TipRmtBinSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:bin_number, :integer).maybe(:int?)
    required(:device, Types::StrippedString).maybe(:str?)
  end
end
