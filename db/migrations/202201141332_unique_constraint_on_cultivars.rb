Sequel.migration do
  up do
    alter_table(:cultivars) do
      add_unique_constraint :cultivar_name, name: :cultivar_name_uniq
    end
  end

  down do
    alter_table(:cultivars) do
      drop_constraint :cultivar_name_uniq
    end
  end
end
