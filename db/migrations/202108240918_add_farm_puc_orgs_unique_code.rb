Sequel.migration do
  up do
    alter_table(:farm_puc_orgs) do
      drop_index [:organization_id, :farm_id, :puc_id], name: :farm_puc_orgs_idx
      add_index [:organization_id, :farm_id], name: :farm_puc_orgs_unique_code, unique: true
    end

  end

  down do
    alter_table(:farm_puc_orgs) do
      drop_index [:organization_id, :farm_id], name: :farm_puc_orgs_unique_code
      add_index [:organization_id, :farm_id, :puc_id], name: :farm_puc_orgs_idx
    end
  end
end