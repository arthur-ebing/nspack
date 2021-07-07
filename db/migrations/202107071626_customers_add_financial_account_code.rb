Sequel.migration do
  up do
    alter_table(:customers) do
      add_column :financial_account_code, String
    end
  end

  down do
    alter_table(:customers) do
      drop_column :financial_account_code
    end
  end
end
