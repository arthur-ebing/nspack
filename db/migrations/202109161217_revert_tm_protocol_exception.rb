Sequel.migration do
  up do
    alter_table(:target_markets) do
      drop_column :protocol_exception
    end

    alter_table(:govt_inspection_sheets) do
      drop_column :exception_protocol_tm_id
      add_column :titan_protocol_exception, String
    end
  end

  down do
    alter_table(:target_markets) do
      add_column :protocol_exception, :boolean, default: false
    end

    alter_table(:govt_inspection_sheets) do
      add_foreign_key :exception_protocol_tm_id, :target_markets, key: [:id]
      drop_column :titan_protocol_exception
    end
  end
end