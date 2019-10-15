require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:rmt_bins, ignore_index_errors: true) do
      primary_key :id
      foreign_key :rmt_delivery_id, :rmt_deliveries, type: :integer, null: false
      foreign_key :season_id, :seasons, type: :integer, null: false
      foreign_key :cultivar_id, :cultivars, type: :integer, null: false
      foreign_key :orchard_id, :orchards, type: :integer, null: false
      foreign_key :farm_id, :farms, type: :integer, null: false
      foreign_key :rmt_class_id, :rmt_classes, type: :integer
      foreign_key :rmt_container_material_owner_id, :rmt_container_material_owners, type: :integer
      foreign_key :rmt_container_type_id, :rmt_container_types, type: :integer, null: false
      foreign_key :rmt_container_material_type_id, :rmt_container_material_types, type: :integer
      foreign_key :cultivar_group_id, :cultivar_groups, type: :integer
      foreign_key :puc_id, :pucs, type: :integer
      String :exit_ref
      String :bin_fullness
      Integer :qty_bins
      Integer :bin_asset_number
      Integer :tipped_asset_number
      Integer :rmt_inner_container_type_id
      Integer :rmt_inner_container_material_id
      Integer :qty_inner_bins
      Integer :production_run_rebin_id
      Integer :production_run_tipped_id
      Integer :production_run_tipping_id
      Integer :bin_tipping_plant_resource_id
      Decimal :nett_weight
      Decimal :gross_weight
      TrueClass :active, default: true
      TrueClass :bin_tipped, default: false
      TrueClass :tipping, default: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      DateTime :bin_received_date_time
      DateTime :bin_tipped_date_time
      DateTime :exit_ref_date_time
      DateTime :bin_tipping_started_date_time
      DateTime :rebin_created_at

      # index [:bin_asset_number], name: :rmt_bins_unique_bin_asset_number, unique: true
    end

    pgt_created_at(:rmt_bins,
                   :created_at,
                   function_name: :rmt_bins_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:rmt_bins,
                   :updated_at,
                   function_name: :rmt_bins_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('rmt_bins', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    drop_trigger(:rmt_bins, :audit_trigger_row)
    drop_trigger(:rmt_bins, :audit_trigger_stm)

    drop_trigger(:rmt_bins, :set_created_at)
    drop_function(:rmt_bins_set_created_at)
    drop_trigger(:rmt_bins, :set_updated_at)
    drop_function(:rmt_bins_set_updated_at)
    drop_table(:rmt_bins)
  end
end
