Sequel.migration do
  up do
    alter_table(:pallet_mix_rules) do
      add_column :allow_puc_mix, TrueClass, default: false
      add_column :allow_orchard_mix, TrueClass, default: false
    end
  end

  down do
    alter_table(:pallet_mix_rules) do
      drop_column :allow_puc_mix
      drop_column :allow_orchard_mix
    end
  end
end
