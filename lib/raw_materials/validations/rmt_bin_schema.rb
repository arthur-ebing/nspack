# frozen_string_literal: true

module RawMaterialsApp
  RmtBinSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:orchard_id, :integer).filled(:int?)
    required(:rmt_delivery_id, :integer).filled(:int?)
    required(:season_id, :integer).filled(:int?)
    required(:cultivar_id, :integer).filled(:int?)
    required(:puc_id, :integer).filled(:int?)
    required(:qty_bins, :integer).maybe(:int?)
    optional(:qty_inner_bins, :integer).maybe(:int?)
    optional(:nett_weight, :decimal).maybe(:decimal?)
    required(:rmt_container_type_id, :integer).filled(:int?)
    optional(:rmt_container_material_type_id, :integer).filled(:int?)
    optional(:location_id, :integer).filled(:int?)
    optional(:rmt_material_owner_party_role_id, :integer).filled(:int?)
    required(:bin_received_date_time, :date_time).maybe(:date_time?)
    optional(:rmt_inner_container_type_id, :integer).maybe(:int?)
    optional(:rmt_inner_container_material_id, :integer).maybe(:int?)
    optional(:farm_id, :integer).filled(:int?)
    required(:bin_fullness, Types::StrippedString).maybe(:str?)
    optional(:bin_asset_number, Types::StrippedString).maybe(:str?)
    optional(:scrapped, :bool).maybe(:bool?)
    optional(:scrapped_at, %i[nil time]).maybe(:time?)
    optional(:scrapped_bin_asset_number, Types::StrippedString).maybe(:str?)
  end
end
