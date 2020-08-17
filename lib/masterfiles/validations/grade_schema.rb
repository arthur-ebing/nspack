# frozen_string_literal: true

module MasterfilesApp
  GradeSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:grade_code, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).maybe(:str?)
    required(:rmt_grade, :bool).maybe(:bool?)
  end
end
