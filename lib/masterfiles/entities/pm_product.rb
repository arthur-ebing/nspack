# frozen_string_literal: true

module MasterfilesApp
  class PmProduct < Dry::Struct
    attribute :id, Types::Integer
    attribute :pm_subtype_id, Types::Integer
    attribute :std_fruit_size_count_id, Types::Integer
    attribute :erp_code, Types::String
    attribute :product_code, Types::String
    attribute :description, Types::String
    attribute :pm_type_code, Types::String
    attribute :pm_subtype_code, Types::String
    attribute :material_mass, Types::Decimal
    attribute :basic_pack_id, Types::Integer
    attribute :basic_pack_code, Types::String
    attribute :height_mm, Types::Integer
    attribute :composition_level, Types::Integer
    attribute :composition_level_description, Types::String
    attribute :gross_weight_per_unit, Types::Decimal
    attribute :items_per_unit, Types::Integer
    attribute :items_per_unit_client_description, Types::String
    attribute? :active, Types::Bool
  end
end
