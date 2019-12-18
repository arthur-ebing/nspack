Sequel.migration do
  up do
    alter_table(:fruit_size_references) do
      add_column :edi_out_code, String
    end
  end

  down do
    alter_table(:fruit_size_references) do
      drop_column :edi_out_code
    end
  end
end
