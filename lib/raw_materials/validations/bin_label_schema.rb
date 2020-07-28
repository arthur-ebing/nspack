# frozen_string_literal: true

module RawMaterialsApp
  PreprintScreenInput = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:printer, Types::StrippedString).filled(:str?)
    required(:bin_label, Types::StrippedString).filled(:str?)
  end

  BinLabelSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:cultivar_id, :integer).filled(:int?)
    required(:farm_id, :integer).filled(:int?)
    required(:puc_id, :integer).filled(:int?)
    required(:orchard_id, :integer).filled(:int?)
    optional(:bin_received_at, %i[nil time]).maybe(:time?)
    required(:bin_asset_number, Types::StrippedString).filled(:str?)
  end
end
