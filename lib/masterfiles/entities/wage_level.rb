# frozen_string_literal: true

module MasterfilesApp
  class WageLevel < Dry::Struct
    attribute :id, Types::Integer
    attribute :wage_level, Types::Decimal
    attribute :description, Types::String
  end
end
