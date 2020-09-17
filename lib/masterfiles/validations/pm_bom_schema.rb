# frozen_string_literal: true

module MasterfilesApp
  PmBomSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:bom_code).filled(Types::StrippedString)
    required(:erp_bom_code).maybe(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
