Sequel.migration do
  up do
    alter_table(:pallet_sequences) do
      add_foreign_key :source_bin_id , :rmt_bins, key: [:id], null: true
    end
  end

  down do
    alter_table(:pallet_sequences) do
      drop_column :source_bin_id
    end
  end
end
