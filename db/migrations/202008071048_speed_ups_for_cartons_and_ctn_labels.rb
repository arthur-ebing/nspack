Sequel.migration do
  up do
    alter_table(:carton_labels) do
      drop_index :created_at, name: :cartons_reated_at_idx
    end

    alter_table(:carton_labels) do
      add_index :created_at, name: :carton_labels_created_at_idx
    end
  end

  down do
    alter_table(:carton_labels) do
      add_index :created_at, name: :cartons_reated_at_idx
    end

    alter_table(:carton_labels) do
      drop_index :created_at, name: :carton_labels_created_at_idx
    end
  end
end
