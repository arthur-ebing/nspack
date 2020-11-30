require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:rmt_sizes, ignore_index_errors: true) do
      primary_key :id
      String :size_code, null: false
      String :description
    end
  end

  down do
    drop_table(:rmt_sizes)
  end
end
