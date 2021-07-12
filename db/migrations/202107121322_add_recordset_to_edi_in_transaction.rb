Sequel.migration do
  up do
    alter_table :edi_in_transactions do
      add_column :recordset, :jsonb
    end
  end

  down do
    alter_table :edi_in_transactions do
      drop_column :recordset
    end
  end
end
