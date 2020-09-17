# frozen_string_literal: true

module MasterfilesApp
  ProductionRegionSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:production_region_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
