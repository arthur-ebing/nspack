Sequel.migration do
  up do
    alter_table(:pallet_mix_rules) do
      add_column :allow_cultivar_mix, TrueClass, default: false
      add_column :allow_cultivar_group_mix, TrueClass, default: false
    end
  end

  down do
    alter_table(:pallet_mix_rules) do
      drop_column :allow_cultivar_mix
      drop_column :allow_cultivar_group_mix
    end
  end
end
