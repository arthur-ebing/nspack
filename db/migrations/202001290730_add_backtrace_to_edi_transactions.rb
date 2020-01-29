Sequel.migration do
  up do
    alter_table(:edi_in_transactions) do
      add_column :backtrace, String
    end

    alter_table(:edi_out_transactions) do
      add_column :backtrace, String
    end
  end

  down do
    alter_table(:edi_in_transactions) do
      drop_column :backtrace
    end

    alter_table(:edi_out_transactions) do
      drop_column :backtrace
    end
  end
end
