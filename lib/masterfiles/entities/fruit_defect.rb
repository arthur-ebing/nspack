# frozen_string_literal: true

module MasterfilesApp
  class FruitDefect < Dry::Struct
    attribute :id, Types::Integer
    attribute :fruit_defect_type_id, Types::Integer
    attribute :fruit_defect_code, Types::String
    attribute :short_description, Types::String
    attribute :description, Types::String
    attribute :internal, Types::Bool
    attribute :reporting_description, Types::String
    attribute :external, Types::Bool
    attribute :pre_harvest, Types::Bool
    attribute :post_harvest, Types::Bool
    attribute :severity, Types::String
    attribute :qc_class_2, Types::Bool
    attribute :qc_class_3, Types::Bool
    attribute? :active, Types::Bool
  end

  class FruitDefectFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :defect_category, Types::String
    attribute :fruit_defect_category_id, Types::Integer
    attribute :fruit_defect_type_name, Types::String
    attribute :fruit_defect_type_id, Types::Integer
    attribute :fruit_defect_code, Types::String
    attribute :short_description, Types::String
    attribute :description, Types::String
    attribute :internal, Types::Bool
    attribute :reporting_description, Types::String
    attribute :external, Types::Bool
    attribute :pre_harvest, Types::Bool
    attribute :post_harvest, Types::Bool
    attribute :severity, Types::String
    attribute :qc_class_2, Types::Bool
    attribute :qc_class_3, Types::Bool
    attribute? :active, Types::Bool
  end
end
