require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:costs, ignore_index_errors: true) do
      primary_key :id
      foreign_key :cost_type_id, :cost_types, type: :integer, null: false
      String :cost_code, null: false
      String :description
      Decimal :default_amount
    end
  end

  down do
    drop_table(:costs)
  end
end
