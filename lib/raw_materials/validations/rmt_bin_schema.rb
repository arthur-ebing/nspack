# frozen_string_literal: true

module RawMaterialsApp
  RmtBinSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:orchard_id, :integer).filled(:int?)
    required(:rmt_delivery_id, :integer).filled(:int?)
    required(:season_id, :integer).filled(:int?)
    required(:cultivar_id, :integer).filled(:int?)
    required(:qty_bins, :integer).maybe(:int?)
    optional(:qty_inner_bins, :integer).maybe(:int?)
    optional(:nett_weight, :decimal).maybe(:decimal?)
    required(:rmt_container_type_id, :integer).filled(:int?)
    optional(:rmt_container_material_type_id, :integer).filled(:int?) # UI
    optional(:rmt_container_material_owner_id, :integer).filled(:int?) # UI
    required(:bin_received_date_time, :date_time).maybe(:date_time?)
    optional(:rmt_inner_container_type_id, :integer).maybe(:int?)
    optional(:rmt_inner_container_material_id, :integer).maybe(:int?)
    optional(:farm_id, :integer).filled(:int?)
    required(:bin_fullness, Types::StrippedString).maybe(:str?)

    #   required(:rmt_class_id, :integer).filled(:int?)
    #   required(:cultivar_group_id, :integer).filled(:int?)
    #   required(:puc_id, :integer).filled(:int?)
    #   required(:status, Types::StrippedString).maybe(:str?)
    #   required(:exit_ref, Types::StrippedString).maybe(:str?)
    #   required(:bin_asset_number, :integer).maybe(:int?)
    #   required(:tipped_asset_number, :integer).maybe(:int?)
    #   required(:production_run_rebin_id, :integer).maybe(:int?)
    #   required(:production_run_tipped_id, :integer).maybe(:int?)
    #   required(:production_run_tipping_id, :integer).maybe(:int?)
    #   required(:bin_tipping_plant_resource_id, :integer).maybe(:int?)
    #   required(:gross_weight, :decimal).maybe(:decimal?)
    #   required(:bin_tipped, :bool).maybe(:bool?)
    #   required(:tipping, :bool).maybe(:bool?)
    #   required(:bin_tipped_date_time, :date_time).maybe(:date_time?)
    #   required(:exit_ref_date_time, :date_time).maybe(:date_time?)
    #   required(:bin_tipping_started_date_time, :date_time).maybe(:date_time?)
    #   required(:rebin_created_at, :date_time).maybe(:date_time?)
  end
end
