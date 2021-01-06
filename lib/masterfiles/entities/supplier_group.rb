# frozen_string_literal: true

module MasterfilesApp
  class SupplierGroup < Dry::Struct
    attribute :id, Types::Integer
    attribute :supplier_group_code, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end
end
