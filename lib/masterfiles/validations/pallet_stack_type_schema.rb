# frozen_string_literal: true

module MasterfilesApp
  PalletStackTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:stack_type_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:stack_height).filled(:integer)
  end
end
