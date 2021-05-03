# frozen_string_literal: true

module MasterfilesApp
  InspectionTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:inspection_type_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:inspection_failure_type_id).filled(:integer)
    required(:passed_default).maybe(:bool)
    required(:applies_to_all_tms).maybe(:bool)
    required(:applicable_tm_ids).maybe(:array).maybe { each(:integer) }
    required(:applies_to_all_tm_customers).maybe(:bool)
    required(:applicable_tm_customer_ids).maybe(:array).maybe { each(:integer) }
    required(:applies_to_all_grades).maybe(:bool)
    required(:applicable_grade_ids).maybe(:array).maybe { each(:integer) }
    required(:applies_to_all_marketing_org_party_roles).maybe(:bool)
    required(:applicable_marketing_org_party_role_ids).maybe(:array).maybe { each(:integer) }
  end
end
