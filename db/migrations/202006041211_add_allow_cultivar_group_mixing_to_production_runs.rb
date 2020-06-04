Sequel.migration do
  up do
    alter_table(:production_runs) do
      add_column :allow_cultivar_group_mixing, :boolean, default: false
    end
  end

  down do
    alter_table(:production_runs) do
      drop_column :allow_cultivar_group_mixing
    end
  end
end
