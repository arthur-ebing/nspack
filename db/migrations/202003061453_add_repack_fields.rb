Sequel.migration do
  up do
    alter_table(:pallets) do
      add_column :repacked, TrueClass, default: false
      add_column :repacked_at, DateTime
    end

    alter_table(:pallet_sequences) do
      add_column :repacked_at, DateTime
      add_column :repacked_from_pallet_id, Integer
    end
  end

  down do
    alter_table(:pallets) do
      drop_column :repacked
      drop_column :repacked_at
    end

    alter_table(:pallet_sequences) do
      drop_column :repacked_at
      drop_column :repacked_from_pallet_id
    end
  end
end
