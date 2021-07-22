# frozen_string_literal: true

module FinishedGoodsApp
  class Order < Dry::Struct
    attribute :id, Types::Integer
    attribute :order_id, Types::Integer
    attribute :order_type_id, Types::Integer
    attribute :order_type, Types::String
    attribute :sales_person_party_role_id, Types::Integer
    attribute :sales_person, Types::String
    attribute :customer_party_role_id, Types::Integer
    attribute :customer, Types::String
    attribute :contact_party_role_id, Types::Integer
    attribute :contact, Types::String
    attribute :currency_id, Types::Integer
    attribute :currency, Types::String
    attribute :deal_type_id, Types::Integer
    attribute :deal_type, Types::String
    attribute :incoterm_id, Types::Integer
    attribute :incoterm, Types::String
    attribute :customer_payment_term_set_id, Types::Integer
    attribute :customer_payment_term_set, Types::String
    attribute :target_customer_party_role_id, Types::Integer
    attribute :target_customer, Types::String
    attribute :exporter_party_role_id, Types::Integer
    attribute :exporter, Types::String
    attribute :packed_tm_group_id, Types::Integer
    attribute :packed_tm_group, Types::String
    attribute :final_receiver_party_role_id, Types::Integer
    attribute :final_receiver, Types::String
    attribute :marketing_org_party_role_id, Types::Integer
    attribute :marketing_org, Types::String
    attribute :allocated, Types::Bool
    attribute :shipped, Types::Bool
    attribute :completed, Types::Bool
    attribute :completed_at, Types::DateTime
    attribute :customer_order_number, Types::String
    attribute :internal_order_number, Types::String
    attribute :order_number, Types::String
    attribute :remarks, Types::String
    attribute :pricing_per_kg, Types::Bool
    attribute? :status, Types::String
    attribute? :active, Types::Bool
  end

  class OrderItem < Dry::Struct
    attribute :id, Types::Integer
    attribute :order_id, Types::Integer
    attribute :load_id, Types::Integer
    attribute :packed_tm_group_id, Types::Integer
    attribute :marketing_org_party_role_id, Types::Integer
    attribute :target_customer_party_role_id, Types::Integer
    attribute :commodity_id, Types::Integer
    attribute :commodity, Types::String
    attribute :basic_pack_id, Types::Integer
    attribute :basic_pack, Types::String
    attribute :standard_pack_id, Types::Integer
    attribute :standard_pack, Types::String
    attribute :actual_count_id, Types::Integer
    attribute :actual_count, Types::String
    attribute :size_reference_id, Types::Integer
    attribute :size_reference, Types::String
    attribute :grade_id, Types::Integer
    attribute :grade, Types::String
    attribute :mark_id, Types::Integer
    attribute :mark, Types::String
    attribute :marketing_variety_id, Types::Integer
    attribute :marketing_variety, Types::String
    attribute :inventory_id, Types::Integer
    attribute :inventory, Types::String
    attribute :carton_quantity, Types::Integer
    attribute :price_per_carton, Types::Decimal
    attribute :price_per_kg, Types::Decimal
    attribute :sell_by_code, Types::String
    attribute :pallet_format_id, Types::Integer
    attribute :pallet_format, Types::String
    attribute :pm_mark_id, Types::Integer
    attribute :pkg_mark, Types::String
    attribute :pm_bom_id, Types::Integer
    attribute :pkg_bom, Types::String
    attribute :rmt_class_id, Types::Integer
    attribute :rmt_class, Types::String
    attribute :treatment_id, Types::Integer
    attribute :treatment, Types::String
    attribute? :status, Types::String
    attribute? :active, Types::Bool
  end

  class OrdersLoads < Dry::Struct
    attribute :id, Types::Integer
    attribute :load_id, Types::Integer
    attribute :order_id, Types::Integer
    attribute? :active, Types::Bool
  end
end
