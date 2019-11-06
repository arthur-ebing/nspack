Sequel.migration do
  up do
    alter_table(:scrap_reasons) do
      add_column :applies_to_pallets, TrueClass, default: true
    end
  end

  down do
    alter_table(:scrap_reasons) do
      drop_column :applies_to_pallets
    end
  end
end
