# frozen_string_literal: true

module MasterfilesApp
  FruitDefectCategorySchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:defect_category).filled(Types::StrippedString)
    required(:reporting_description).maybe(Types::StrippedString)
  end
end
