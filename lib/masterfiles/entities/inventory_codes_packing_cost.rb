# frozen_string_literal: true

module MasterfilesApp
  class InventoryCodesPackingCost < Dry::Struct
    attribute :id, Types::Integer
    attribute :inventory_code_id, Types::Integer
    attribute :commodity_id, Types::Integer
    attribute :packing_cost, Types::Decimal
  end

  class InventoryCodesPackingCostFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :inventory_code_id, Types::Integer
    attribute :commodity_id, Types::Integer
    attribute :packing_cost, Types::Decimal
    attribute :inventory_code, Types::String
    attribute :inventory_description, Types::String
    attribute :commodity_code, Types::String
    attribute :commodity_description, Types::String
  end
end
