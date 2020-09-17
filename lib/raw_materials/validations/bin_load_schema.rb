# frozen_string_literal: true

module RawMaterialsApp
  BinLoadSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:bin_load_purpose_id).maybe(:integer)
    required(:customer_party_role_id).filled(:integer)
    required(:transporter_party_role_id).maybe(:integer)
    required(:dest_depot_id).filled(:integer)
    required(:qty_bins).filled(:integer)
    optional(:shipped_at).maybe(:time)
    optional(:shipped).maybe(:bool)
    optional(:completed_at).maybe(:time)
    optional(:completed).maybe(:bool)
  end

  ScanBinLoadSchema = Dry::Schema.Params do
    required(:bin_load_id).filled(:integer)
  end

  ScanBinToBinLoadSchema = Dry::Schema.Params do
    required(:bin_load_id).filled(:integer)
    required(:bin_asset_number).maybe(Types::StrippedString)
  end
end
