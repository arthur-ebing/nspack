Sequel.migration do
  up do
    alter_table(:pm_subtypes) do
      drop_index [:subtype_code], name: :pm_subtypes_unique_code
      add_index [:pm_type_id, :subtype_code], name: :pm_subtypes_unique_code, unique: true
    end
  end

  down do
    alter_table(:pm_subtypes) do
      drop_index [:pm_type_id, :subtype_code], name: :pm_subtypes_unique_code
      add_index [:subtype_code], name: :pm_subtypes_unique_code, unique: true
    end
  end
end
