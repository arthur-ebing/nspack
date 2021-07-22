Sequel.migration do
  up do
    create_table(:inventory_codes_packing_costs , ignore_index_errors: true) do
      primary_key :id
      foreign_key :inventory_code_id, :inventory_codes, type: :integer, null: false
      foreign_key :commodity_id, :commodities, type: :integer, null: false
      BigDecimal :packing_cost

      index [:inventory_code_id, :commodity_id], name: :inventory_codes_packing_costs_idx, unique: true
    end
  end

  down do
    drop_table :inventory_codes_packing_costs
  end
end
