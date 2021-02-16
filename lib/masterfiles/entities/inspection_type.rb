# frozen_string_literal: true

module MasterfilesApp
  class InspectionType < Dry::Struct
    attribute :id, Types::Integer
    attribute :inspection_type_code, Types::String
    attribute :description, Types::String
    attribute :inspection_failure_type_id, Types::Integer
    attribute :failure_type_code, Types::String
    attribute :passed_default, Types::Bool
    attribute :applies_to_all_tm_groups, Types::Bool
    attribute :applicable_tm_group_ids, Types::Array
    attribute :applicable_tm_groups, Types::Array
    attribute :applies_to_all_grades, Types::Bool
    attribute :applicable_grade_ids, Types::Array
    attribute :applicable_grades, Types::Array
    attribute? :active, Types::Bool
  end
end
