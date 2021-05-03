# frozen_string_literal: true

module MasterfilesApp
  class InspectionType < Dry::Struct
    attribute :id, Types::Integer
    attribute :inspection_type_code, Types::String
    attribute :description, Types::String
    attribute :inspection_failure_type_id, Types::Integer
    attribute :failure_type_code, Types::String
    attribute :passed_default, Types::Bool

    attribute :applies_to_all_tms, Types::Bool
    attribute :applicable_tm_ids, Types::Array
    attribute :applicable_tms, Types::Array

    attribute :applies_to_all_tm_customers, Types::Bool
    attribute :applicable_tm_customer_ids, Types::Array
    attribute :applicable_tm_customers, Types::Array

    attribute :applies_to_all_grades, Types::Bool
    attribute :applicable_grade_ids, Types::Array
    attribute :applicable_grades, Types::Array

    attribute :applies_to_all_marketing_org_party_roles, Types::Bool
    attribute :applicable_marketing_org_party_role_ids, Types::Array
    attribute :applicable_marketing_org_party_roles, Types::Array
    attribute? :active, Types::Bool
  end
end
