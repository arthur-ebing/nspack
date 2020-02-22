require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:employment_types, ignore_index_errors: true) do
      primary_key :id
      String :code, null: false

      index [:code], name: :fki_employment_types_unique_code, unique: true
    end

    create_table(:contract_types, ignore_index_errors: true) do
      primary_key :id
      String :code, null: false
      String :description, text: true

      index [:code], name: :fki_contract_types_unique_code, unique: true
    end

    create_table(:wage_levels, ignore_index_errors: true) do
      primary_key :id
      BigDecimal :wage_level, null: false, size: [17,5]
      String :description
    end

    create_table(:contract_workers, ignore_index_errors: true) do
      primary_key :id
      foreign_key :employment_type_id, :employment_types, null: false, key: [:id]
      foreign_key :contract_type_id, :contract_types, null: false, key: [:id]
      foreign_key :wage_level_id, :wage_levels, null: false, key: [:id]

      String :first_name, null: false
      String :surname, null: false
      String :title
      String :email
      String :contact_number
      String :personnel_number

      DateTime :start_date
      DateTime :end_date

      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      TrueClass :active, default: true

      index [:personnel_number], name: :contract_workers_unique_personnel_number, unique: true
    end
    pgt_created_at(:contract_workers, :created_at, function_name: :contract_workers_set_created_at, trigger_name: :set_created_at)
    pgt_updated_at(:contract_workers, :updated_at, function_name: :contract_workers_set_updated_at, trigger_name: :set_updated_at)
  end

  down do
    drop_trigger(:contract_workers, :set_created_at)
    drop_function(:contract_workers_set_created_at)
    drop_trigger(:contract_workers, :set_updated_at)
    drop_function(:contract_workers_set_updated_at)
    drop_table(:contract_workers)

    drop_table(:wage_levels)
    drop_table(:contract_types)
    drop_table(:employment_types)
  end
end
