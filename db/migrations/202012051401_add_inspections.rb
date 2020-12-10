require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:inspection_types, ignore_index_errors: true) do
      primary_key :id
      String :inspection_type_code, null: false
      String :description
      foreign_key :inspection_failure_type_id, :inspection_failure_types, type: :integer, null: false

      TrueClass :applies_to_all_tm_groups, default: true
      column :applicable_tm_group_ids, 'integer[]'
      TrueClass :applies_to_all_cultivars, default: true
      column :applicable_cultivar_ids, 'integer[]'
      TrueClass :applies_to_all_orchards, default: true
      column :applicable_orchard_ids, 'integer[]'

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:inspection_type_code], name: :orchard_test_types_unique_code, unique: true
    end

    pgt_created_at(:inspection_types,
                   :created_at,
                   function_name: :inspection_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:inspection_types,
                   :updated_at,
                   function_name: :inspection_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('inspection_types', true, true, '{updated_at}'::text[]);"

    create_table(:inspections, ignore_index_errors: true) do
      primary_key :id
      foreign_key :inspection_type_id, :inspection_types, type: :integer, null: false
      foreign_key :pallet_id, :pallets, type: :integer, null: false
      foreign_key :carton_id, :cartons, type: :integer
      foreign_key :inspector_id, :inspectors, type: :integer

      column :inspection_failure_reason_ids, 'integer[]'
      TrueClass :passed, default: true
      String :remarks

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:inspection_type_code], name: :orchard_test_types_unique_code, unique: true
    end

    pgt_created_at(:inspections,
                   :created_at,
                   function_name: :inspections_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:inspections,
                   :updated_at,
                   function_name: :inspections_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('inspections', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    drop_trigger(:inspections, :audit_trigger_row)
    drop_trigger(:inspections, :audit_trigger_stm)

    drop_trigger(:inspections, :set_created_at)
    drop_function(:inspections_set_created_at)
    drop_trigger(:inspections, :set_updated_at)
    drop_function(:inspections_set_updated_at)
    drop_table(:inspections)


    # Drop logging for this table.
    drop_trigger(:inspection_types, :audit_trigger_row)
    drop_trigger(:inspection_types, :audit_trigger_stm)

    drop_trigger(:inspection_types, :set_created_at)
    drop_function(:inspection_types_set_created_at)
    drop_trigger(:inspection_types, :set_updated_at)
    drop_function(:inspection_types_set_updated_at)
    drop_table(:inspection_types)
  end
end
