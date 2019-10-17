Sequel.migration do
  up do
    alter_table(:pallets) do
      add_column :nett_weight, :decimal
    end

    alter_table(:pallet_sequences) do
      add_column :pick_ref, String
    end
  end

  down do
    alter_table(:pallets) do
      drop_column :nett_weight
    end

    alter_table(:pallet_sequences) do
      drop_column :pick_ref
    end
  end
end
