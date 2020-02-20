Sequel.migration do
  up do
    add_column :orchards, :otmc_results, 'hstore'
    add_column :cultivars, :registered_code, String
    add_column :pallet_sequences, :failed_otmc_results, String
    add_column :pallet_sequences, :pallet_failed_otmc_results, String
  end

  down do
    drop_column :pallet_sequences, :failed_otmc_results
    drop_column :pallet_sequences, :pallet_failed_otmc_results
    drop_column :cultivars, :registered_code
    drop_column :orchards, :otmc_results
  end
end