require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:standard_product_weights, ignore_index_errors: true) do
      primary_key :id

      foreign_key :commodity_id, :commodities, type: :integer, null: false
      foreign_key :standard_pack_id, :standard_pack_codes, type: :integer, null: false
      BigDecimal :gross_weight, null: false
      BigDecimal :nett_weight, null: false


      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:standard_product_weights,
                   :created_at,
                   function_name: :standard_product_weight_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:standard_product_weights,
                   :updated_at,
                   function_name: :standard_product_weight_set_updated_at,
                   trigger_name: :set_updated_at)
  end

  down do
    drop_trigger(:standard_product_weights, :set_created_at)
    drop_function(:standard_product_weight_set_created_at)
    drop_trigger(:standard_product_weights, :set_updated_at)
    drop_function(:standard_product_weight_set_updated_at)
    drop_table :standard_product_weights
  end
end
