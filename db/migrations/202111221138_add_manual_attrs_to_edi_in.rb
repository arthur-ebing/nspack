Sequel.migration do
  up do
    alter_table(:edi_in_transactions) do
      add_column :manual_process, TrueClass, default: false
      add_column :manual_header, :jsonb
    end
  end

  down do
    alter_table(:edi_in_transactions) do
      drop_column :manual_process
      drop_column :manual_header
    end
  end
end
