require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:farm_sections, ignore_index_errors: true) do
      primary_key :id
      # foreign_key :farm_id, :farms, type: :integer, null: false
      foreign_key :farm_manager_party_role_id, :party_roles, type: :integer, null: false
      String :farm_section_name, null: false
      String :description
    end
  end

  down do
    drop_table(:farm_sections)
  end
end
