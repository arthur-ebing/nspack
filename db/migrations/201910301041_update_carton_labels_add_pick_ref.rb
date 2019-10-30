Sequel.migration do
  up do
    alter_table(:carton_labels) do
      add_column :pick_ref, String
    end

    alter_table(:cartons) do
      add_column :pick_ref, String
    end
  end

  down do
    alter_table(:carton_labels) do
      drop_column :pick_ref
    end

    alter_table(:cartons) do
      drop_column :pick_ref
    end
  end
end
