# frozen_string_literal: true

module MasterfilesApp
  class Cost < Dry::Struct
    attribute :id, Types::Integer
    attribute :cost_type_id, Types::Integer
    attribute :cost_code, Types::String
    attribute :default_amount, Types::Decimal
    attribute :description, Types::String
  end

  class CostFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :cost_type_id, Types::Integer
    attribute :cost_code, Types::String
    attribute :default_amount, Types::Decimal
    attribute :description, Types::String
    attribute :cost_type_code, Types::String
  end
end
