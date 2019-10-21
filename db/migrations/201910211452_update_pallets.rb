Sequel.migration do
  up do
    alter_table(:pallets) do
      add_column :load_id, :integer
    end
  end

  down do
    alter_table(:pallets) do
      drop_column :load_id
    end
  end
end
