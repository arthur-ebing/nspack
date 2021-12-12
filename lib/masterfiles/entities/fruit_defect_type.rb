# frozen_string_literal: true

module MasterfilesApp
  class FruitDefectType < Dry::Struct
    attribute :id, Types::Integer
    attribute :fruit_defect_type_name, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end
end
