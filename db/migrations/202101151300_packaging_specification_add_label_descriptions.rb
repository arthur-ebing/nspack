Sequel.migration do
  up do
      add_column(:pm_products, :items_per_unit_client_description, String)
      add_column(:pm_boms, :label_description, String)
      add_column(:pm_boms_products, :composition_description, String)
  end

  down do
      drop_column(:pm_products, :items_per_unit_client_description)
      drop_column(:pm_boms, :label_description)
      drop_column(:pm_boms_products, :composition_description)
  end
end
