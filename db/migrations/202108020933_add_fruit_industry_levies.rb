require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:fruit_industry_levies , ignore_index_errors: true) do
      primary_key :id
      String :levy_code, null: false
      String :description
      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:levy_code], name: :fruit_industry_levy_unique_code, unique: true
    end

    pgt_created_at(:fruit_industry_levies,
                   :created_at,
                   function_name: :fruit_industry_levies_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:fruit_industry_levies,
                   :updated_at,
                   function_name: :fruit_industry_levies_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('fruit_industry_levies', true, true, '{updated_at}'::text[]);"

    alter_table(:customers) do
      add_foreign_key :fruit_industry_levy_id, :fruit_industry_levies, null: true, key: [:id]
    end
  end

  down do
    alter_table(:customers) do
      drop_column :fruit_industry_levy_id
    end

    drop_trigger(:fruit_industry_levies, :audit_trigger_row)
    drop_trigger(:fruit_industry_levies, :audit_trigger_stm)

    drop_trigger(:fruit_industry_levies, :set_created_at)
    drop_function(:fruit_industry_levies_set_created_at)
    drop_trigger(:fruit_industry_levies, :set_updated_at)
    drop_function(:fruit_industry_levies_set_updated_at)
    drop_table :fruit_industry_levies
  end
end
