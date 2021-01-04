Sequel.migration do
  up do
    alter_table(:pallets) do
      add_column :nett_weight_externally_calculated, :boolean, default: false
    end
  end

  down do
    alter_table(:pallets) do
      drop_column :nett_weight_externally_calculated
    end
  end
end