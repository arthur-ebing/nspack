# frozen_string_literal: true

module ProductionApp
  class ProductSetup < Dry::Struct
    attribute :id, Types::Integer
    attribute :product_setup_template_id, Types::Integer
    attribute :marketing_variety_id, Types::Integer
    attribute :customer_variety_id, Types::Integer
    attribute :std_fruit_size_count_id, Types::Integer
    attribute :basic_pack_code_id, Types::Integer
    attribute :standard_pack_code_id, Types::Integer
    attribute :fruit_actual_counts_for_pack_id, Types::Integer
    attribute :fruit_size_reference_id, Types::Integer
    attribute :marketing_org_party_role_id, Types::Integer
    attribute :packed_tm_group_id, Types::Integer
    attribute :mark_id, Types::Integer
    attribute :inventory_code_id, Types::Integer
    attribute :pallet_format_id, Types::Integer
    attribute :cartons_per_pallet_id, Types::Integer
    attribute :client_size_reference, Types::String
    attribute :client_product_code, Types::String
    attribute :treatment_ids, Types::Array
    attribute :marketing_order_number, Types::String
    attribute :sell_by_code, Types::String
    attribute :pallet_label_name, Types::String
    attribute? :active, Types::Bool
    attribute :product_setup_code, Types::String
    attribute? :in_production, Types::Bool
    attribute :commodity_id, Types::Integer
    attribute :grade_id, Types::Integer
    attribute :product_chars, Types::String
    attribute :pallet_base_id, Types::Integer
    attribute :pallet_stack_type_id, Types::Integer
    attribute :target_market_id, Types::Integer
    attribute :gtin_code, Types::String
    attribute :rmt_class_id, Types::Integer
    attribute :target_customer_party_role_id, Types::Integer
    attribute :colour_percentage_id, Types::Integer
    attribute :carton_label_template_id, Types::Integer
  end

  class ProductSetupFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :product_setup_template_id, Types::Integer
    attribute :marketing_variety_id, Types::Integer
    attribute :customer_variety_id, Types::Integer
    attribute :std_fruit_size_count_id, Types::Integer
    attribute :basic_pack_code_id, Types::Integer
    attribute :standard_pack_code_id, Types::Integer
    attribute :fruit_actual_counts_for_pack_id, Types::Integer
    attribute :fruit_size_reference_id, Types::Integer
    attribute :marketing_org_party_role_id, Types::Integer
    attribute :packed_tm_group_id, Types::Integer
    attribute :mark_id, Types::Integer
    attribute :inventory_code_id, Types::Integer
    attribute :pallet_format_id, Types::Integer
    attribute :cartons_per_pallet_id, Types::Integer
    attribute :client_size_reference, Types::String
    attribute :client_product_code, Types::String
    attribute :treatment_ids, Types::Array
    attribute :marketing_order_number, Types::String
    attribute :sell_by_code, Types::String
    attribute :pallet_label_name, Types::String
    attribute? :active, Types::Bool
    attribute :product_setup_code, Types::String
    attribute? :in_production, Types::Bool
    attribute :commodity_id, Types::Integer
    attribute :grade_id, Types::Integer
    attribute :product_chars, Types::String
    attribute :pallet_base_id, Types::Integer
    attribute :pallet_stack_type_id, Types::Integer
    attribute :target_market_id, Types::Integer
    attribute :gtin_code, Types::String
    attribute :rmt_class_id, Types::Integer
    attribute :target_customer_party_role_id, Types::Integer
    attribute :colour_percentage_id, Types::Integer
    attribute :product_setup_template, Types::String
    attribute :cultivar_group_id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :cultivar_group, Types::String
    attribute :cultivar, Types::String
    attribute :carton_label_template_id, Types::Integer
    attribute :carton_template_name, Types::String
  end
end
