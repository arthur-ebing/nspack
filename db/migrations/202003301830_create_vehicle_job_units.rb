require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:vehicle_job_units, ignore_index_errors: true) do
      primary_key :id
      foreign_key :vehicle_job_id, :vehicle_jobs, type: :integer, null: false
      foreign_key :stock_type_id, :stock_types, type: :integer, null: false
      Integer :stock_item_id, null: false
      DateTime :loaded_at
      DateTime :offloaded_at
    end
  end

  down do
    drop_table(:vehicle_job_units)
  end
end
