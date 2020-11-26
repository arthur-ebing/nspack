Sequel.migration do
  up do
    alter_table(:pm_boms) do
      add_column :gross_weight, :decimal
      add_column :nett_weight, :decimal
    end
  end

  down do
    alter_table(:pm_boms) do
      drop_column :gross_weight
      drop_column :nett_weight
    end
  end
end
