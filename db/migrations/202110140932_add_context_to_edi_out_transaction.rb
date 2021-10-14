Sequel.migration do
  up do
    alter_table(:edi_out_transactions) do
      add_column :context, :jsonb
    end
  end

  down do
    alter_table(:edi_out_transactions) do
      drop_column :context
    end
  end
end
