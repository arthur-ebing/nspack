# frozen_string_literal: true

module MasterfilesApp
  WageLevelSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:wage_level).filled(:decimal)
    required(:description).maybe(Types::StrippedString)
  end
end
