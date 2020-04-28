require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers

    alter_table(:rmt_container_material_owners) do
      add_primary_key :id
      drop_index [:rmt_container_material_type_id, :rmt_material_owner_party_role_id], name: :fki_rmt_container_material_type_party_roles
      add_index [:rmt_container_material_type_id, :rmt_material_owner_party_role_id], name: :fki_rmt_container_material_type_party_roles, unique: true
    end

    create_table(:empty_bin_locations, ignore_index_errors: true) do
      primary_key :id
      foreign_key :rmt_container_material_owner_id, :rmt_container_material_owners, null: false, key: [:id]
      foreign_key :location_id, :locations, null: false, key: [:id]

      Integer :quantity

      index [:location_id], name: :fki_empty_bin_locations_locations
      index [:rmt_container_material_owner_id], name: :fki_empty_bin_locations_rmt_container_material_owners
      index [:location_id, :rmt_container_material_owner_id], name: :fki_empty_bin_locations_rmt_container_material_owners_locations, unique: true
    end

    create_table(:asset_transaction_types, ignore_index_errors: true) do
      primary_key :id
      String :transaction_type_code, null: false
      String :description, null: false

      index [:transaction_type_code], name: :asset_transaction_types_unique_transaction_type_code, unique: true
    end

    create_table(:empty_bin_transactions, ignore_index_errors: true) do
      primary_key :id
      foreign_key :asset_transaction_type_id, :asset_transaction_types, null: false, key: [:id]
      foreign_key :empty_bin_to_location_id, :locations, null: false, key: [:id]
      foreign_key :fruit_reception_delivery_id, :rmt_deliveries, key: [:id]
      foreign_key :business_process_id, :business_processes, key: [:id]

      Integer :quantity_bins, null: false
      String :truck_registration_number
      String :reference_number, null: false
      String :created_by
      TrueClass :is_adhoc, default: false

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:asset_transaction_type_id], name: :fki_empty_bin_transactions_asset_transaction_types
      index [:empty_bin_to_location_id], name: :fki_empty_bin_transactions_to_locations
      index [:fruit_reception_delivery_id], name: :fki_empty_bin_transactions_rmt_deliveries
      index [:business_process_id], name: :fki_empty_bin_transactions_business_processes
    end
    pgt_created_at(:empty_bin_transactions,
                   :created_at,
                   function_name: :empty_bin_transactions_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:empty_bin_transactions,
                   :updated_at,
                   function_name: :empty_bin_transactions_set_updated_at,
                   trigger_name: :set_updated_at)

    create_table(:empty_bin_transaction_items, ignore_index_errors: true) do
      primary_key :id
      foreign_key :empty_bin_transaction_id, :empty_bin_transactions, null: false, key: [:id]
      foreign_key :rmt_container_material_owner_id, :rmt_container_material_owners, null: false, key: [:id]
      foreign_key :empty_bin_from_location_id, :locations, key: [:id]
      foreign_key :empty_bin_to_location_id, :locations, key: [:id]

      Integer :quantity_bins, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:empty_bin_transaction_id], name: :fki_empty_bin_transaction_items_empty_bin_transactions
      index [:rmt_container_material_owner_id], name: :fki_empty_bin_transaction_items_rmt_container_material_owners
      index [:empty_bin_from_location_id], name: :fki_empty_bin_transactions_from_locations
      index [:empty_bin_to_location_id], name: :fki_empty_bin_transactions_to_locations
    end
    pgt_created_at(:empty_bin_transaction_items,
                   :created_at,
                   function_name: :empty_bin_transaction_items_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:empty_bin_transaction_items,
                   :updated_at,
                   function_name: :empty_bin_transaction_items_set_updated_at,
                   trigger_name: :set_updated_at)
  end

  down do
    drop_trigger(:empty_bin_transaction_items, :set_created_at)
    drop_function(:empty_bin_transaction_items_set_created_at)
    drop_trigger(:empty_bin_transaction_items, :set_updated_at)
    drop_function(:empty_bin_transaction_items_set_updated_at)
    drop_table(:empty_bin_transaction_items)

    drop_trigger(:empty_bin_transactions, :set_created_at)
    drop_function(:empty_bin_transactions_set_created_at)
    drop_trigger(:empty_bin_transactions, :set_updated_at)
    drop_function(:empty_bin_transactions_set_updated_at)
    drop_table(:empty_bin_transactions)

    drop_table(:asset_transaction_types)
    drop_table(:empty_bin_locations)

    alter_table(:rmt_container_material_owners) do
      drop_column :id
      drop_index [:rmt_container_material_type_id, :rmt_material_owner_party_role_id], name: :fki_rmt_container_material_type_party_roles, unique: true
      add_index [:rmt_container_material_type_id, :rmt_material_owner_party_role_id], name: :fki_rmt_container_material_type_party_roles
    end
  end
end
