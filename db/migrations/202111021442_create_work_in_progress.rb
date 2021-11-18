Sequel.migration do
  up do
    create_table(:wip_bins, ignore_index_errors: true) do
      primary_key :id
      foreign_key :rmt_bin_id, :rmt_bins, type: :integer, null: false
      String :context
    end

    create_table(:wip_pallets, ignore_index_errors: true) do
      primary_key :id
      foreign_key :pallet_id, :pallets, type: :integer, null: false
      String :context
    end
  end

  down do
    drop_table :wip_bins
    drop_table :wip_pallets
  end
end
