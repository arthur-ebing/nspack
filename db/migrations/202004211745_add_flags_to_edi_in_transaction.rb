Sequel.migration do
  up do
    alter_table(:edi_in_transactions) do
      add_column :schema_valid, TrueClass, default: false
      add_column :newer_edi_received, TrueClass, default: false
      add_column :has_missing_master_files, TrueClass, default: false
      add_column :valid, TrueClass, default: false
      add_column :has_discrepancies, TrueClass, default: false
      add_column :reprocessed, TrueClass, default: false
      add_column :notes, String

      add_index [:file_name, :complete], name: :edi_in_tran_file_complete
      add_index :created_at, name: :edi_in_tran_created
    end
  end

  down do
    alter_table(:edi_in_transactions) do
      drop_index [:file_name, :complete], name: :edi_in_tran_file_complete
      drop_index :created_at, name: :edi_in_tran_created

      drop_column :schema_valid
      drop_column :newer_edi_received
      drop_column :has_missing_master_files
      drop_column :valid
      drop_column :has_discrepancies
      drop_column :reprocessed
      drop_column :notes
    end
  end
end
