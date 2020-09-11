# frozen_string_literal: true

module MasterfilesApp
  PmProductSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:pm_subtype_id).filled(:integer)
    required(:erp_code).filled(Types::StrippedString)
    required(:product_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
