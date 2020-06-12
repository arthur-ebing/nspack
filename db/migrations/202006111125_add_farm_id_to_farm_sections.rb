
Sequel.migration do
  up do
    alter_table(:farm_sections) do
      add_foreign_key :farm_id, :farms, key: [:id]
      add_unique_constraint [:farm_id, :farm_section_name], name: :farm_farm_section_name_unique_code
    end
  end

  down do
    alter_table(:farm_sections) do
      drop_constraint [:farm_id, :farm_section_name], name: :farm_farm_section_name_unique_code
      drop_foreign_key :farm_id
    end
  end

end
