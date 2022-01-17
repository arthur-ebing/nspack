# frozen_string_literal: true

module RawMaterialsApp
  RmtBinSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:orchard_id).filled(:integer)
    required(:rmt_delivery_id).filled(:integer)
    optional(:rmt_class_id).maybe(:integer)
    required(:season_id).filled(:integer)
    required(:cultivar_id).filled(:integer)
    required(:puc_id).filled(:integer)
    required(:qty_bins).maybe(:integer, gt?: 0)
    optional(:qty_inner_bins).maybe(:integer)
    optional(:nett_weight).maybe(:decimal)
    required(:rmt_container_type_id).filled(:integer)
    optional(:rmt_container_material_type_id).filled(:integer)
    optional(:location_id).maybe(:integer)
    optional(:rmt_material_owner_party_role_id).filled(:integer)
    required(:bin_received_date_time).maybe(:time)
    optional(:rmt_inner_container_type_id).maybe(:integer)
    optional(:rmt_inner_container_material_id).maybe(:integer)
    optional(:farm_id).filled(:integer)
    required(:bin_fullness).filled(Types::StrippedString)
    optional(:bin_asset_number).maybe(Types::StrippedString)
    optional(:scrapped).maybe(:bool)
    optional(:scrapped_at).maybe(:time)
    optional(:scrapped_bin_asset_number).maybe(Types::StrippedString)
    optional(:scrapped_rmt_delivery_id).maybe(:integer)
    optional(:rmt_code_id).maybe(:integer)
    optional(:rmt_classifications).maybe(:array)
  end

  RmtRebinBinSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:orchard_id).filled(:integer)
    required(:rmt_class_id).filled(:integer)
    required(:season_id).filled(:integer)
    required(:production_run_rebin_id).filled(:integer)
    required(:cultivar_id).filled(:integer)
    required(:puc_id).filled(:integer)
    required(:qty_bins).maybe(:integer)
    optional(:qty_inner_bins).maybe(:integer)
    required(:gross_weight).filled(:decimal)
    optional(:nett_weight).maybe(:decimal)
    required(:rmt_container_type_id).filled(:integer)
    optional(:rmt_container_material_type_id).filled(:integer)
    optional(:location_id).maybe(:integer)
    optional(:rmt_material_owner_party_role_id).filled(:integer)
    # required(:bin_received_date_time).maybe(:time)
    optional(:rmt_inner_container_type_id).maybe(:integer)
    optional(:rmt_inner_container_material_id).maybe(:integer)
    optional(:farm_id).filled(:integer)
    required(:bin_fullness).filled(Types::StrippedString)
    optional(:bin_asset_number).maybe(Types::StrippedString)
    optional(:scrapped).maybe(:bool)
    optional(:scrapped_at).maybe(:time)
    optional(:scrapped_bin_asset_number).maybe(Types::StrippedString)
    optional(:is_rebin).maybe(:bool)
    optional(:converted_from_pallet_sequence_id).maybe(:integer)
    optional(:cultivar_group_id).maybe(:integer)
    optional(:rmt_size_id).maybe(:integer)
    optional(:scrapped_rmt_delivery_id).maybe(:integer)
    optional(:legacy_data).maybe(:hash)
    optional(:colour_percentage_id).maybe(:integer)
    optional(:actual_cold_treatment_id).maybe(:integer)
    optional(:actual_ripeness_treatment_id).maybe(:integer)
    optional(:rmt_code_id).maybe(:integer)
  end

  UpdateRmtRebinBinSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:orchard_id).filled(:integer)
    optional(:rmt_delivery_id).filled(:integer)
    required(:rmt_class_id).filled(:integer)
    required(:season_id).filled(:integer)
    required(:production_run_rebin_id).filled(:integer)
    required(:cultivar_id).filled(:integer)
    required(:puc_id).filled(:integer)
    optional(:qty_bins).maybe(:integer)
    optional(:qty_inner_bins).maybe(:integer)
    required(:gross_weight).filled(:decimal)
    optional(:nett_weight).maybe(:decimal)
    optional(:rmt_container_type_id).filled(:integer)
    optional(:rmt_container_material_type_id).filled(:integer)
    optional(:location_id).maybe(:integer)
    optional(:rmt_material_owner_party_role_id).filled(:integer)
    # required(:bin_received_date_time).maybe(:time)
    optional(:rmt_inner_container_type_id).maybe(:integer)
    optional(:rmt_inner_container_material_id).maybe(:integer)
    optional(:farm_id).filled(:integer)
    required(:bin_fullness).filled(Types::StrippedString)
    optional(:bin_asset_number).maybe(Types::StrippedString)
    optional(:scrapped).maybe(:bool)
    optional(:scrapped_at).maybe(:time)
    optional(:scrapped_bin_asset_number).maybe(Types::StrippedString)
    optional(:is_rebin).maybe(:bool)
    optional(:scrapped_rmt_delivery_id).maybe(:integer)
  end
end
