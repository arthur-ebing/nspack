# frozen_string_literal: true

module MasterfilesApp
  RmtClassSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:rmt_class_code).filled(Types::StrippedString)
    required(:description).filled(Types::StrippedString)
  end
end
