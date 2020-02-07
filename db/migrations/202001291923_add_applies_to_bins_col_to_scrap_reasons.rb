Sequel.migration do
  up do
    alter_table(:scrap_reasons) do
      add_column :applies_to_bins, TrueClass, default: false
    end
  end

  down do
    alter_table(:scrap_reasons) do
      drop_column :applies_to_bins
    end
  end
end
