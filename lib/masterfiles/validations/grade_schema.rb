# frozen_string_literal: true

module MasterfilesApp
  GradeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:grade_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:rmt_grade).maybe(:bool)
    required(:qa_level).maybe(:integer)
    required(:inspection_class).maybe(Types::StrippedString)
  end
end
