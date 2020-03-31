require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers

    # -- ecert_agreements
    create_table(:ecert_agreements, ignore_index_errors: true) do
      primary_key :id

      String :code, null: false
      String :name, null: false
      String :description
      Date :start_date
      Date :end_date

      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:code], name: :ecert_agreements_unique_code, unique: true
    end

    pgt_created_at(:ecert_agreements,
                   :created_at,
                   function_name: :ecert_agreements_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:ecert_agreements,
                   :updated_at,
                   function_name: :ecert_agreements_set_updated_at,
                   trigger_name: :set_updated_at)
  end

  down do
    # Drop logging for ecert_agreements table.
    drop_trigger(:ecert_agreements, :set_created_at)
    drop_function(:ecert_agreements_set_created_at)
    drop_trigger(:ecert_agreements, :set_updated_at)
    drop_function(:ecert_agreements_set_updated_at)
    drop_table(:ecert_agreements)
  end
end
