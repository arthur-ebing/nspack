# frozen_string_literal: true

module MasterfilesApp
  EmploymentTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:employment_type_code).filled(Types::StrippedString)
  end
end
