Sequel.migration do
  up do
    alter_table(:customers) do
      add_column :currency_ids, 'integer[]'
    end
  end

  down do
    alter_table(:customers) do
      drop_column :currency_ids
    end
  end
end
