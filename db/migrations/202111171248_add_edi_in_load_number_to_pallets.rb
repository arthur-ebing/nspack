Sequel.migration do
  up do
    alter_table(:pallets) do
      add_column :edi_in_load_number, String
    end
  end

  down do
    alter_table(:pallets) do
      drop_column :edi_in_load_number
    end
  end
end
