Sequel.migration do
  up do
    alter_table(:shifts) do
      add_column :extended_columns, :jsonb
    end
  end

  down do
    alter_table(:shifts) do
      drop_column :extended_columns
    end
  end
end
