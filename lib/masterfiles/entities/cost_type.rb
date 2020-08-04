# frozen_string_literal: true

module MasterfilesApp
  class CostType < Dry::Struct
    attribute :id, Types::Integer
    attribute :cost_type_code, Types::String
    attribute :cost_unit, Types::String
    attribute :description, Types::String
  end
end
