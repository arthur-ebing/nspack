Sequel.migration do
  up do
    alter_table(:orchards) do
      add_foreign_key :farm_section_id, :farm_sections, key: [:id]
    end
  end

  down do
    alter_table(:orchards) do
      drop_foreign_key :farm_section_id
    end
  end
end
