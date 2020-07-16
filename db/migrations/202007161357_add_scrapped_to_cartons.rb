Sequel.migration do
  up do
    alter_table(:cartons) do
      add_column :scrapped, TrueClass, default: false
      add_column :scrapped_reason, String
      add_column :scrapped_at, DateTime
      add_column :scrapped_sequence_id, Integer
    end
  end

  down do
    alter_table(:cartons) do
      drop_column :scrapped
      drop_column :scrapped_reason
      drop_column :scrapped_at
      drop_column :scrapped_sequence_id
    end
  end
end
