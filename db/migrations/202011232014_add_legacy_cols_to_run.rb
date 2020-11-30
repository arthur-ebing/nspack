Sequel.migration do
  up do
    extension :pg_json
    add_column :production_runs, :legacy_data, :jsonb
    add_column :production_runs, :legacy_bintip_criteria, :jsonb
  end

  down do
    drop_column :production_runs, :legacy_data
    drop_column :production_runs, :legacy_bintip_criteria
  end
end