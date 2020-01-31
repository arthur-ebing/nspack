Sequel.migration do
  up do
    alter_table(:pallets) do
      add_column :edi_in_inspection_point, String
    end
  end

  down do
    alter_table(:pallets) do
      drop_column :edi_in_inspection_point
    end
  end
end
