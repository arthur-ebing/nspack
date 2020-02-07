Sequel.migration do
  up do
    alter_table(:reworks_runs) do
      add_column :allow_cultivar_mixing, TrueClass, default: false
    end
  end

  down do
    alter_table(:reworks_runs) do
      drop_column :allow_cultivar_mixing
    end
  end
end
