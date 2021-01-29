# frozen_string_literal: true

module MasterfilesApp
  class PmBomsProduct < Dry::Struct
    attribute :id, Types::Integer
    attribute :pm_product_id, Types::Integer
    attribute :pm_bom_id, Types::Integer
    attribute :uom_id, Types::Integer
    attribute :quantity, Types::Decimal
    attribute :product_code, Types::String
    attribute :bom_code, Types::String
    attribute :uom_code, Types::String
    attribute :last_product, Types::Bool
    attribute? :active, Types::Bool
  end
end
