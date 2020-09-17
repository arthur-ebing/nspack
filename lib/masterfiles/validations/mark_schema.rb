# frozen_string_literal: true

module MasterfilesApp
  MarkSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:mark_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
