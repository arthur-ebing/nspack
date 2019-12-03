# require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    alter_table(:govt_inspection_sheets) do
      add_foreign_key :govt_inspection_api_result_id, :govt_inspection_api_results, type: :integer
    end
  end

  down do
    alter_table(:govt_inspection_sheets) do
      drop_foreign_key :govt_inspection_api_result_id
    end
  end
end
