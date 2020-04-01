require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:vehicle_jobs, ignore_index_errors: true) do
      primary_key :id
      String :vehicle_number
      foreign_key :govt_inspection_sheet_id, :govt_inspection_sheets, type: :integer, null: false
      foreign_key :planned_location_to_id, :locations, type: :integer, null: false
      foreign_key :business_process_id, :business_processes, type: :integer, null: false
      foreign_key :stock_type_id, :stock_types, type: :integer, null: false
      DateTime :loaded_at
      DateTime :offloaded_at
    end
  end

  down do
    drop_table(:vehicle_jobs)
  end
end
