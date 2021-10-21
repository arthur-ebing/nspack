Sequel.migration do
  up do
    create_table(:bin_sequences , ignore_index_errors: true) do
      primary_key :id
      foreign_key :rmt_bin_id, :rmt_bins, type: :integer, null: false
      foreign_key :farm_id, :farms, type: :integer, null: false
      foreign_key :orchard_id, :orchards, type: :integer, null: false
      Decimal :nett_weight
      String :presort_run_lot_number
    end
  end

  down do
    drop_table :bin_sequences
  end
end
