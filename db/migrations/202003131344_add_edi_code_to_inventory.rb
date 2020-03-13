Sequel.migration do
  up do
    alter_table(:inventory_codes) do
      add_column :edi_out_inventory_code, String
    end
  end

  down do
    alter_table(:inventory_codes) do
      drop_column :edi_out_inventory_code
    end
  end
end
