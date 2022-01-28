Sequel.migration do
  up do
    create_table(:bin_asset_register, ignore_index_errors: true) do
      primary_key :id
      foreign_key :rmt_container_material_owner_id, :rmt_container_material_owners, null: false, key: [:id]
      Integer :quantity_bins, null: false
    end

  end

  down do
    drop_table(:bin_asset_register)
  end
end
