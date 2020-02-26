Sequel.migration do
  up do
    alter_table(:target_market_groups) do
      add_column :description, String
    end

    alter_table(:target_markets) do
      add_column :description, String
    end
  end

  down do
    alter_table(:target_market_groups) do
      drop_column :description
    end

    alter_table(:target_markets) do
      drop_column :description
    end
  end
end
