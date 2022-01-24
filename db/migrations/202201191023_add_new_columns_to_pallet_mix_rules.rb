Sequel.migration do
  up do
    alter_table(:pallet_mix_rules) do
      add_column :allow_variety_mix, TrueClass, default: false
      add_column :allow_marketing_org_mix, TrueClass, default: false
      add_column :allow_sell_by_mix, TrueClass, default: false
    end
  end

  down do
    alter_table(:pallet_mix_rules) do
      drop_column :allow_variety_mix
      drop_column :allow_marketing_org_mix
      drop_column :allow_sell_by_mix
    end
  end
end
