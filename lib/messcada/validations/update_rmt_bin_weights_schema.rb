# frozen_string_literal: true

module MesscadaApp
  UpdateRmtBinWeightsSchema = Dry::Schema.Params do
    required(:bin_number).maybe(Types::StrippedString)
    required(:gross_weight).maybe(:decimal)
    required(:measurement_unit).maybe(Types::StrippedString)
  end

  RmtRebinSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:orchard_id).filled(:integer)
    required(:rmt_class_id).maybe(:integer)
    required(:season_id).filled(:integer)
    required(:production_run_rebin_id).filled(:integer)
    required(:cultivar_id).filled(:integer)
    required(:puc_id).filled(:integer)
    required(:qty_bins).maybe(:integer)
    optional(:qty_inner_bins).maybe(:integer)
    required(:gross_weight).maybe(:decimal)
    optional(:nett_weight).maybe(:decimal)
    required(:rmt_container_type_id).filled(:integer)
    optional(:rmt_container_material_type_id).filled(:integer)
    optional(:location_id).maybe(:integer)
    optional(:rmt_material_owner_party_role_id).filled(:integer)
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
    required(:verified_from_carton_label_id).filled(:integer)
    optional(:legacy_data).maybe(:hash)
  end
end
