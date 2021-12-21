# frozen_string_literal: true

module MasterfilesApp
  class FruitDefectType < Dry::Struct
    attribute :id, Types::Integer
    attribute :fruit_defect_type_name, Types::String
    attribute :description, Types::String
    attribute :fruit_defect_category_id, Types::Integer
    attribute :reporting_description, Types::String
    attribute? :active, Types::Bool
  end

  class FruitDefectTypeFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :fruit_defect_type_name, Types::String
    attribute :description, Types::String
    attribute :fruit_defect_category_id, Types::Integer
    attribute :defect_category, Types::String
    attribute :reporting_description, Types::String
    attribute? :active, Types::Bool
  end
end
