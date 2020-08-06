Sequel.migration do
  up do
    alter_table(:cartons) do
      add_index :carton_label_id, name: :cartons_carton_label_id_idx
    end

    alter_table(:carton_labels) do
      add_index :created_at, name: :cartons_reated_at_idx
    end
  end

  down do
    alter_table(:cartons) do
      drop_index :carton_label_id, name: :cartons_carton_label_id_idx
    end

    alter_table(:carton_labels) do
      drop_index :created_at, name: :cartons_reated_at_idx
    end
  end
end
