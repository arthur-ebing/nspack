# frozen_string_literal: true

module ProductionApp
  class ProductResourceAllocation < Dry::Struct
    attribute :id, Types::Integer
    attribute :production_run_id, Types::Integer
    attribute :plant_resource_id, Types::Integer
    attribute :product_setup_id, Types::Integer
    attribute :label_template_id, Types::Integer
    attribute :packing_method_id, Types::Integer
    attribute? :active, Types::Bool
    attribute :target_customer_party_role_id, Types::Integer
    attribute :packing_specification_item_id, Types::Integer
  end

  class ProductResourceAllocationFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :production_run_id, Types::Integer
    attribute :plant_resource_id, Types::Integer
    attribute :product_setup_id, Types::Integer
    attribute :label_template_id, Types::Integer
    attribute :packing_method_id, Types::Integer
    attribute? :active, Types::Bool
    attribute :product_setup_code, Types::String
    attribute :label_template_name, Types::String
    attribute :packing_method_code, Types::String
    attribute :target_customer_party_role_id, Types::Integer
    attribute :target_customer, Types::String
    attribute :packing_specification_item_id, Types::Integer
    attribute :packing_specification_code, Types::String
  end
end
