require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:pallet_verification_failure_reasons, ignore_index_errors: true) do
      primary_key :id
      String :reason, null: false
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:reason], name: :reasons_unique_code, unique: true
    end

    pgt_created_at(:pallet_verification_failure_reasons,
                   :created_at,
                   function_name: :pallet_verification_failure_reasons_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:pallet_verification_failure_reasons,
                   :updated_at,
                   function_name: :pallet_verification_failure_reasons_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('pallet_verification_failure_reasons', true, true, '{updated_at}'::text[]);"

    create_table(:pallets, ignore_index_errors: true) do
      primary_key :id
      String :pallet_number, null: false
      String :exit_ref
      DateTime :exit_ref_date_time
      foreign_key :location_id, :locations, type: :integer, null: false
      TrueClass :shipped, default: false
      TrueClass :in_stock, default: false
      TrueClass :inspected, default: false
      DateTime :shipped_date_time
      DateTime :govt_first_inspection_date_time
      DateTime :govt_reinspection_date_time
      DateTime :internal_inspection_date_time
      DateTime :internal_reinspection_date_time
      DateTime :stock_date_time
      String :phc, null: false
      DateTime :intake_date_time
      DateTime :cold_date_time
      String :build_status
      Decimal :gross_weight
      DateTime :gross_weight_measured_at
      TrueClass :palletized, default: false
      TrueClass :partially_palletized, default: false
      DateTime :palletized_date_time
      DateTime :partially_palletized_date_time
      foreign_key :fruit_sticker_pm_product_id, :pm_products, type: :integer
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:pallet_number], name: :pallets_unique_code, unique: true
      index [:id, :pallet_number], name: :pallet_idx, unique: true

    end

    pgt_created_at(:pallets,
                   :created_at,
                   function_name: :pallets_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:pallets,
                   :updated_at,
                   function_name: :pallets_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('pallets', true, true, '{updated_at}'::text[]);"

    create_table(:pallet_sequences, ignore_index_errors: true) do
      primary_key :id
      foreign_key :pallet_id, :pallets, type: :integer, null: false
      String :pallet_number, null: false
      Integer :pallet_sequence_number, null: false
      foreign_key :production_run_id, :production_runs, type: :integer, null: false
      foreign_key :farm_id, :farms, type: :integer, null: false
      foreign_key :puc_id, :pucs, type: :integer, null: false
      foreign_key :orchard_id, :orchards, type: :integer, null: false
      foreign_key :cultivar_group_id, :cultivar_groups, type: :integer, null: false
      foreign_key :cultivar_id, :cultivars, type: :integer
      foreign_key :product_resource_allocation_id, :product_resource_allocations, type: :integer, null: false
      foreign_key :packhouse_resource_id, :plant_resources, type: :integer, null: false
      foreign_key :production_line_resource_id, :plant_resources, type: :integer
      foreign_key :season_id, :seasons, type: :integer, null: false
      foreign_key :marketing_variety_id, :marketing_varieties, type: :integer, null: false
      foreign_key :customer_variety_variety_id, :customer_variety_varieties, type: :integer
      foreign_key :std_fruit_size_count_id, :std_fruit_size_counts, type: :integer
      foreign_key :basic_pack_code_id, :basic_pack_codes, type: :integer, null: false
      foreign_key :standard_pack_code_id, :standard_pack_codes, type: :integer, null: false
      foreign_key :fruit_actual_counts_for_pack_id, :fruit_actual_counts_for_packs, type: :integer
      foreign_key :fruit_size_reference_id, :fruit_size_references, type: :integer, null: false
      foreign_key :marketing_org_party_role_id, :party_roles, type: :integer, null: false
      foreign_key :packed_tm_group_id, :target_market_groups, type: :integer, null: false
      foreign_key :mark_id, :marks, type: :integer, null: false
      foreign_key :inventory_code_id, :inventory_codes, type: :integer, null: false
      foreign_key :pallet_format_id, :pallet_formats, type: :integer, null: false
      foreign_key :cartons_per_pallet_id, :cartons_per_pallet, type: :integer, null: false
      foreign_key :pm_bom_id, :pm_boms, type: :integer
      Jsonb :extended_columns
      String :client_size_reference
      String :client_product_code
      column :treatment_ids, 'int[]'
      String :marketing_order_number
      foreign_key :pm_type_id, :pm_types, type: :integer
      foreign_key :pm_subtype_id, :pm_subtypes, type: :integer
      Integer :carton_quantity, null: false
      foreign_key :scanned_from_carton_id, :cartons, type: :integer, null: false
      String :exit_ref
      DateTime :exit_ref_date_time
      String :verification_result
      foreign_key :pallet_verification_failure_reason_id, :pallet_verification_failure_reasons, type: :integer
      DateTime :verified_at
      Decimal :nett_weight
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:pallet_number, :pallet_sequence_number], name: :pallet_sequences_idx, unique: true
      index [:pallet_id, :pallet_number, :pallet_sequence_number], name: :pallet_sequences_unique_idx, unique: true

    end

    pgt_created_at(:pallet_sequences,
                   :created_at,
                   function_name: :pallet_sequences_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:pallet_sequences,
                   :updated_at,
                   function_name: :pallet_sequences_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('pallet_sequences', true, true, '{updated_at}'::text[]);"
  end

  down do
    drop_trigger(:pallet_sequences, :audit_trigger_row)
    drop_trigger(:pallet_sequences, :audit_trigger_stm)

    drop_trigger(:pallet_sequences, :set_created_at)
    drop_function(:pallet_sequences_set_created_at)
    drop_trigger(:pallet_sequences, :set_updated_at)
    drop_function(:pallet_sequences_set_updated_at)
    drop_table(:pallet_sequences)

    drop_trigger(:pallets, :audit_trigger_row)
    drop_trigger(:pallets, :audit_trigger_stm)

    drop_trigger(:pallets, :set_created_at)
    drop_function(:pallets_set_created_at)
    drop_trigger(:pallets, :set_updated_at)
    drop_function(:pallets_set_updated_at)
    drop_table(:pallets)

    drop_trigger(:pallet_verification_failure_reasons, :audit_trigger_row)
    drop_trigger(:pallet_verification_failure_reasons, :audit_trigger_stm)

    drop_trigger(:pallet_verification_failure_reasons, :set_created_at)
    drop_function(:pallet_verification_failure_reasons_set_created_at)
    drop_trigger(:pallet_verification_failure_reasons, :set_updated_at)
    drop_function(:pallet_verification_failure_reasons_set_updated_at)
    drop_table(:pallet_verification_failure_reasons)
  end
end
