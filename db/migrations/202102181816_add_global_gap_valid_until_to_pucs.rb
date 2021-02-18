Sequel.migration do
  up do
    alter_table(:pucs) do
      add_column :gap_code_valid_from, DateTime
      add_column :gap_code_valid_until, DateTime
    end
  end

  down do
    alter_table(:pucs) do
      drop_column :gap_code_valid_from
      drop_column :gap_code_valid_until
    end
  end
end
