# frozen_string_literal: true

module MasterfilesApp
  class PmProduct < Dry::Struct
    attribute :id, Types::Integer
    attribute :pm_subtype_id, Types::Integer
    attribute :erp_code, Types::String
    attribute :product_code, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
    attribute :subtype_code, Types::String
    attribute :material_mass, Types::Decimal
    attribute :basic_pack_id, Types::Integer
    attribute :basic_pack_code, Types::String
    attribute :height_mm, Types::Integer
  end
end
