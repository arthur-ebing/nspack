# frozen_string_literal: true

module MasterfilesApp
  class InventoryCode < Dry::Struct
    attribute :id, Types::Integer
    attribute :inventory_code, Types::String
    attribute :description, Types::String
    attribute :edi_out_inventory_code, Types::String
    attribute? :active, Types::Bool
  end
end
