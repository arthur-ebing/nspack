Sequel.migration do
  up do
    extension :pg_json
    add_column :rmt_deliveries, :legacy_data, :jsonb
  end

  down do
    drop_column :rmt_deliveries, :legacy_data
  end
end