require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:bin_load_purposes, ignore_index_errors: true) do
      primary_key :id
      String :purpose_code, null: false
      String :description

      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:purpose_code], name: :bin_load_purposes_unique_code, unique: true
    end
    pgt_created_at(:bin_load_purposes,
                   :created_at,
                   function_name: :bin_load_purposes_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:bin_load_purposes,
                   :updated_at,
                   function_name: :bin_load_purposes_set_updated_at,
                   trigger_name: :set_updated_at)

    create_table(:bin_loads, ignore_index_errors: true) do
      primary_key :id
      foreign_key :bin_load_purpose_id, :bin_load_purposes, type: :integer
      foreign_key :customer_party_role_id, :party_roles, type: :integer, null: false
      foreign_key :transporter_party_role_id, :party_roles, type: :integer
      foreign_key :dest_depot_id, :depots, type: :integer, null: false
      Integer :qty_bins, null: false
      DateTime :shipped_at
      TrueClass :shipped, default: false
      DateTime :completed_at
      TrueClass :completed, default: false

      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:bin_loads,
                   :created_at,
                   function_name: :bin_loads_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:bin_loads,
                   :updated_at,
                   function_name: :bin_loads_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('bin_loads', true, true, '{updated_at}'::text[]);"

    create_table(:bin_load_products, ignore_index_errors: true) do
      primary_key :id
      foreign_key :bin_load_id, :bin_loads, type: :integer, null: false
      Integer :qty_bins, null: false
      foreign_key :cultivar_id, :cultivars, type: :integer
      foreign_key :cultivar_group_id, :cultivar_groups, type: :integer
      foreign_key :rmt_container_material_type_id, :rmt_container_material_types, type: :integer
      foreign_key :rmt_material_owner_party_role_id, :party_roles, type: :integer

      foreign_key :farm_id, :farms, type: :integer
      foreign_key :puc_id, :pucs, type: :integer
      foreign_key :orchard_id, :orchards, type: :integer
      foreign_key :rmt_class_id, :rmt_classes, type: :integer

      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:bin_load_products,
                   :created_at,
                   function_name: :bin_load_products_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:bin_load_products,
                   :updated_at,
                   function_name: :bin_load_products_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('bin_load_products', true, true, '{updated_at}'::text[]);"

    alter_table(:rmt_bins) do
      add_foreign_key :bin_load_product_id, :bin_load_products, type: :integer
      add_column :shipped_asset_number, String
    end

    alter_table(:depots) do
      add_column :bin_depot, :boolean, default: false
    end
  end

  down do
    alter_table(:depots) do
      drop_column :bin_depot
    end

    alter_table(:rmt_bins) do
      drop_column :shipped_asset_number
      drop_foreign_key :bin_load_product_id
    end

    # Drop logging for bin_load_products table.
    drop_trigger(:bin_load_products, :audit_trigger_row)
    drop_trigger(:bin_load_products, :audit_trigger_stm)

    drop_trigger(:bin_load_products, :set_created_at)
    drop_function(:bin_load_products_set_created_at)
    drop_trigger(:bin_load_products, :set_updated_at)
    drop_function(:bin_load_products_set_updated_at)
    drop_table(:bin_load_products)

    # Drop logging for bin_loads table.
    drop_trigger(:bin_loads, :audit_trigger_row)
    drop_trigger(:bin_loads, :audit_trigger_stm)

    drop_trigger(:bin_loads, :set_created_at)
    drop_function(:bin_loads_set_created_at)
    drop_trigger(:bin_loads, :set_updated_at)
    drop_function(:bin_loads_set_updated_at)
    drop_table(:bin_loads)

    # Drop logging for bin_load_purposes table.
    drop_trigger(:bin_load_purposes, :set_created_at)
    drop_function(:bin_load_purposes_set_created_at)
    drop_trigger(:bin_load_purposes, :set_updated_at)
    drop_function(:bin_load_purposes_set_updated_at)
    drop_table(:bin_load_purposes)
  end
end
