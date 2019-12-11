require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    create_table(:business_processes, ignore_index_errors: true) do
      primary_key :id
      String :process, null: false
      String :description

      index [:process], name: :business_processes_unique_process, unique: true
    end
  end

  down do
    drop_table(:business_processes)
  end
end
