Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      add_foreign_key :converted_from_pallet_sequence_id , :pallet_sequences, key: [:id], null: true
    end
  end

  down do
    alter_table(:rmt_bins) do
      drop_column :converted_from_pallet_sequence_id
    end
  end
end
