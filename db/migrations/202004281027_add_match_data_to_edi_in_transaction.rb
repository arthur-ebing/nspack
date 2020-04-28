Sequel.migration do
  up do
    alter_table(:edi_in_transactions) do
      add_column :match_data, String, text: true
    end
  end

  down do
    alter_table(:edi_in_transactions) do
      drop_column :match_data
    end
  end
end
