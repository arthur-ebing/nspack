Sequel.migration do
  up do
    alter_table(:pallet_sequences) do
      add_index :pallet_id, name: :pseq_pallet_id_idx
    end
    alter_table(:load_containers) do
      add_index :load_id, name: :load_containers_load_id_idx
    end
    alter_table(:load_vehicles) do
      add_index :load_id, name: :load_vehicles_load_id_idx
    end
    alter_table(:load_voyages) do
      add_index :load_id, name: :load_voyages_load_id_idx
    end
  end

  down do
    alter_table(:pallet_sequences) do
      drop_index :pallet_id, name: :pseq_pallet_id_idx
    end
    alter_table(:load_containers) do
      drop_index :load_id, name: :load_containers_load_id_idx
    end
    alter_table(:load_vehicles) do
      drop_index :load_id, name: :load_vehicles_load_id_idx
    end
    alter_table(:load_voyages) do
      drop_index :load_id, name: :load_voyages_load_id_idx
    end
  end
end
