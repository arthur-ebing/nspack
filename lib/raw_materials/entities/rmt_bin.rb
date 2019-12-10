# frozen_string_literal: true

module RawMaterialsApp
  class RmtBin < Dry::Struct
    attribute :id, Types::Integer
    attribute :rmt_delivery_id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :orchard_id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :rmt_class_id, Types::Integer
    attribute :rmt_material_owner_party_role_id, Types::Integer
    attribute :rmt_container_type_id, Types::Integer
    attribute :rmt_container_material_type_id, Types::Integer
    attribute :cultivar_group_id, Types::Integer
    attribute :puc_id, Types::Integer
    attribute :exit_ref, Types::String
    attribute :qty_bins, Types::Integer
    attribute :bin_asset_number, Types::String
    attribute :tipped_asset_number, Types::String
    attribute :rmt_inner_container_type_id, Types::Integer
    attribute :rmt_inner_container_material_id, Types::Integer
    attribute :qty_inner_bins, Types::Integer
    attribute :production_run_rebin_id, Types::Integer
    attribute :production_run_tipped_id, Types::Integer
    attribute :bin_tipping_plant_resource_id, Types::Integer
    attribute :bin_fullness, Types::String
    attribute :nett_weight, Types::Decimal
    attribute :gross_weight, Types::Decimal
    attribute :bin_tipped, Types::Bool
    attribute :bin_received_date_time, Types::DateTime
    attribute :bin_tipped_date_time, Types::DateTime
    attribute :exit_ref_date_time, Types::DateTime
    attribute :rebin_created_at, Types::DateTime
    attribute :scrapped_at, Types::DateTime
    attribute? :scrapped, Types::Bool
    attribute? :active, Types::Bool
  end

  class RmtBinFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :rmt_delivery_id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :orchard_id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :rmt_class_id, Types::Integer
    attribute :rmt_material_owner_party_role_id, Types::Integer
    attribute :rmt_container_type_id, Types::Integer
    attribute :rmt_container_material_type_id, Types::Integer
    attribute :cultivar_group_id, Types::Integer
    attribute :puc_id, Types::Integer
    attribute :exit_ref, Types::String
    attribute :qty_bins, Types::Integer
    attribute :bin_asset_number, Types::String
    attribute :tipped_asset_number, Types::String
    attribute :rmt_inner_container_type_id, Types::Integer
    attribute :rmt_inner_container_material_id, Types::Integer
    attribute :qty_inner_bins, Types::Integer
    attribute :production_run_rebin_id, Types::Integer
    attribute :production_run_tipped_id, Types::Integer
    attribute :bin_tipping_plant_resource_id, Types::Integer
    attribute :bin_fullness, Types::String
    attribute :nett_weight, Types::Decimal
    attribute :gross_weight, Types::Decimal
    attribute :bin_tipped, Types::Bool
    attribute :bin_received_date_time, Types::DateTime
    attribute :bin_tipped_date_time, Types::DateTime
    attribute :exit_ref_date_time, Types::DateTime
    attribute :rebin_created_at, Types::DateTime
    attribute :scrapped_at, Types::DateTime
    attribute? :scrapped, Types::Bool
    attribute? :active, Types::Bool
    attribute :orchard_code, Types::String
    attribute :farm_code, Types::String
    attribute :puc_code, Types::String
    attribute :cultivar_name, Types::String
    attribute :season_code, Types::String
    attribute :container_type_code, Types::String
    attribute :container_material_type_code, Types::String
    # attribute :container_material_owner_code, Types::String
  end
end
