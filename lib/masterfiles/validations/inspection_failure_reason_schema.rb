# frozen_string_literal: true

module MasterfilesApp
  InspectionFailureReasonSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:inspection_failure_type_id).filled(:integer)
    required(:failure_reason).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:main_factor).maybe(:bool)
    required(:secondary_factor).maybe(:bool)
  end
end
