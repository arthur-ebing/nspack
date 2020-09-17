# frozen_string_literal: true

module MasterfilesApp
  GradeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:grade_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:rmt_grade).maybe(:bool)
  end
end
