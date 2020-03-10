Sequel.migration do
  up do
    add_column :orchards, :otmc_results, 'hstore'
    add_column :cultivars, :cultivar_code, String
    add_column :pallet_sequences, :failed_otmc_results, 'integer[]'
    add_column :pallet_sequences, :phyto_data, String
  end

  down do
    drop_column :pallet_sequences, :phyto_data
    drop_column :pallet_sequences, :failed_otmc_results
    drop_column :cultivars, :cultivar_code
    drop_column :orchards, :otmc_results
  end
end