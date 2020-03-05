require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:orchard_test_types, ignore_index_errors: true) do
      primary_key :id
      String :test_type_code, null: false
      String :description

      TrueClass :applies_to_all_markets, default: true
      TrueClass :applies_to_all_cultivars, default: true
      TrueClass :applies_to_orchard, default: true
      TrueClass :allow_result_capturing, default: true
      TrueClass :pallet_level_result, default: true

      String :api_name
      String :result_type, null: false
      String :result_attribute

      column :applicable_tm_group_ids, 'integer[]'
      column :applicable_cultivar_ids, 'integer[]'
      column :applicable_commodity_group_ids, 'integer[]'

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:test_type_code], name: :orchard_test_types_unique_code, unique: true
    end

    pgt_created_at(:orchard_test_types,
                   :created_at,
                   function_name: :orchard_test_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:orchard_test_types,
                   :updated_at,
                   function_name: :orchard_test_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('orchard_test_types', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    drop_trigger(:orchard_test_types, :audit_trigger_row)
    drop_trigger(:orchard_test_types, :audit_trigger_stm)

    drop_trigger(:orchard_test_types, :set_created_at)
    drop_function(:orchard_test_types_set_created_at)
    drop_trigger(:orchard_test_types, :set_updated_at)
    drop_function(:orchard_test_types_set_updated_at)
    drop_table(:orchard_test_types)
  end
end
