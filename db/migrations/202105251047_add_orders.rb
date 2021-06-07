require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:orders, ignore_index_errors: true) do
      primary_key :id
      foreign_key :order_type_id, :order_types
      foreign_key :customer_party_role_id, :party_roles
      foreign_key :contact_party_role_id, :party_roles
      foreign_key :currency_id, :currencies

      foreign_key :deal_type_id, :deal_types
      foreign_key :incoterm_id, :incoterms
      foreign_key :customer_payment_term_set_id, :customer_payment_term_sets
      foreign_key :target_customer_party_role_id, :party_roles
      foreign_key :exporter_party_role_id, :party_roles
      foreign_key :final_receiver_party_role_id, :party_roles
      foreign_key :marketing_org_party_role_id, :party_roles
      foreign_key :packed_tm_group_id, :target_market_groups

      TrueClass :allocated, default: false, null: false
      TrueClass :shipped, default: false, null: false
      TrueClass :completed, default: false, null: false
      DateTime :completed_at

      String :customer_order_number
      String :internal_order_number
      String :remarks

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:orders,
                   :created_at,
                   function_name: :orders_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:orders,
                   :updated_at,
                   function_name: :orders_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('orders', true, true, '{updated_at}'::text[]);"

    create_table(:order_items, ignore_index_errors: true) do
      primary_key :id
      foreign_key :order_id, :orders, null: false
      foreign_key :load_id, :loads, null: true
      foreign_key :commodity_id, :commodities, null: false
      foreign_key :basic_pack_id, :basic_pack_codes
      foreign_key :standard_pack_id, :standard_pack_codes, null: false
      foreign_key :actual_count_id, :fruit_actual_counts_for_packs, null: false
      foreign_key :size_reference_id, :fruit_size_references
      foreign_key :grade_id, :grades, null: false
      foreign_key :mark_id, :marks, null: false
      foreign_key :marketing_variety_id, :marketing_varieties, null: false
      foreign_key :inventory_id, :inventory_codes, null: false
      foreign_key :pallet_format_id, :pallet_formats
      foreign_key :pm_mark_id, :pm_marks
      foreign_key :pm_bom_id, :pm_boms
      foreign_key :rmt_class_id, :rmt_classes
      foreign_key :treatment_id, :treatments

      Integer :carton_quantity, null: false
      BigDecimal :price_per_carton
      BigDecimal :price_per_kg
      String :sell_by_code

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      unique %i[order_id pallet_format_id carton_quantity price_per_carton price_per_kg commodity_id pm_mark_id pm_bom_id
                rmt_class_id basic_pack_id standard_pack_id actual_count_id size_reference_id grade_id mark_id
                marketing_variety_id inventory_id treatment_id]
    end

    pgt_created_at(:order_items,
                   :created_at,
                   function_name: :order_items_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:order_items,
                   :updated_at,
                   function_name: :order_items_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('order_items', true, true, '{updated_at}'::text[]);"

    run "INSERT INTO currencies (currency) VALUES ('ZAR') ON CONFLICT DO NOTHING"
    run "INSERT INTO customers (customer_party_role_id, default_currency_id)
        select * from(
        SELECT party_roles.id
        FROM party_roles
        JOIN roles ON roles.id = party_roles.role_id
        WHERE roles.name = 'CUSTOMER') parties
        JOIN (SELECT id from currencies where currency = 'ZAR') currencies ON 1=1 ON CONFLICT DO NOTHING"

    create_table(:orders_loads, ignore_index_errors: true) do
      primary_key :id
      foreign_key :load_id, :loads, null: false
      foreign_key :order_id, :orders, null: false

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      unique %i[load_id order_id]
    end

    pgt_created_at(:orders_loads,
                   :created_at,
                   function_name: :orders_loads_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:orders_loads,
                   :updated_at,
                   function_name: :orders_loads_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('orders_loads', true, true, '{updated_at}'::text[]);"

    create_table(:order_items_pallet_sequences, ignore_index_errors: true) do
      primary_key :id
      foreign_key :order_item_id, :order_items, null: false
      foreign_key :pallet_sequence_id, :pallet_sequences, null: false

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      unique %i[order_item_id pallet_sequence_id]
    end

    pgt_created_at(:order_items_pallet_sequences,
                   :created_at,
                   function_name: :order_items_pallet_sequences_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:order_items_pallet_sequences,
                   :updated_at,
                   function_name: :order_items_pallet_sequences_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('order_items_pallet_sequences', true, true, '{updated_at}'::text[]);"
  end

  down do
    drop_trigger(:order_items_pallet_sequences, :audit_trigger_row)
    drop_trigger(:order_items_pallet_sequences, :audit_trigger_stm)

    drop_trigger(:order_items_pallet_sequences, :set_created_at)
    drop_function(:order_items_pallet_sequences_set_created_at)
    drop_trigger(:order_items_pallet_sequences, :set_updated_at)
    drop_function(:order_items_pallet_sequences_set_updated_at)
    drop_table :order_items_pallet_sequences


    drop_trigger(:orders_loads, :audit_trigger_row)
    drop_trigger(:orders_loads, :audit_trigger_stm)

    drop_trigger(:orders_loads, :set_created_at)
    drop_function(:orders_loads_set_created_at)
    drop_trigger(:orders_loads, :set_updated_at)
    drop_function(:orders_loads_set_updated_at)
    drop_table :orders_loads

    drop_trigger(:order_items, :audit_trigger_row)
    drop_trigger(:order_items, :audit_trigger_stm)

    drop_trigger(:order_items, :set_created_at)
    drop_function(:order_items_set_created_at)
    drop_trigger(:order_items, :set_updated_at)
    drop_function(:order_items_set_updated_at)
    drop_table :order_items

    drop_trigger(:orders, :audit_trigger_row)
    drop_trigger(:orders, :audit_trigger_stm)

    drop_trigger(:orders, :set_created_at)
    drop_function(:orders_set_created_at)
    drop_trigger(:orders, :set_updated_at)
    drop_function(:orders_set_updated_at)
    drop_table :orders
  end
end
