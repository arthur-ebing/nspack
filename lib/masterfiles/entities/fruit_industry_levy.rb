# frozen_string_literal: true

module MasterfilesApp
  class FruitIndustryLevy < Dry::Struct
    attribute :id, Types::Integer
    attribute :levy_code, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end
end
