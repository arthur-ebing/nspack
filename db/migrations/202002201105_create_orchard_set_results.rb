require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:orchard_set_results, ignore_index_errors: true) do
      primary_key :id
      foreign_key :orchard_test_type_id, :orchard_test_types, type: :integer
      foreign_key :puc_id, :pucs, type: :integer
      String :description
      String :status_description

      TrueClass :passed, default: true
      TrueClass :classification_only, default: true
      TrueClass :freeze_result, default: true

      column :classifications, 'hstore'
      column :cultivar_ids, 'integer[]'

      DateTime :applicable_from, null: false
      DateTime :applicable_to, null: false

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:orchard_set_results,
                   :created_at,
                   function_name: :orchard_set_results_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:orchard_set_results,
                   :updated_at,
                   function_name: :orchard_set_results_set_updated_at,
                   trigger_name: :set_updated_at)
  end

  down do
    drop_trigger(:orchard_set_results, :set_created_at)
    drop_function(:orchard_set_results_set_created_at)
    drop_trigger(:orchard_set_results, :set_updated_at)
    drop_function(:orchard_set_results_set_updated_at)
    drop_table :orchard_set_results
  end
end
