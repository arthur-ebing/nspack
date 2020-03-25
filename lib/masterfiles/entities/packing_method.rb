# frozen_string_literal: true

module MasterfilesApp
  class PackingMethod < Dry::Struct
    attribute :id, Types::Integer
    attribute :packing_method_code, Types::String
    attribute :description, Types::String
    attribute :actual_count_reduction_factor, Types::Decimal
    attribute? :active, Types::Bool
  end
end
