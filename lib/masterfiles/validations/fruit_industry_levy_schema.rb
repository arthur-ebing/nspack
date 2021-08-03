# frozen_string_literal: true

module MasterfilesApp
  FruitIndustryLevySchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:levy_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
