# frozen_string_literal: true

module MasterfilesApp
  class FruitDefectCategory < Dry::Struct
    attribute :id, Types::Integer
    attribute :defect_category, Types::String
    attribute :reporting_description, Types::String
    attribute? :active, Types::Bool
  end
end
