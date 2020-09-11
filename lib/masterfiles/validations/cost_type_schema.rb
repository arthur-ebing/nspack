# frozen_string_literal: true

module MasterfilesApp
  CostTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:cost_type_code).filled(Types::StrippedString)
    optional(:cost_unit).maybe(Types::StrippedString)
    optional(:description).maybe(Types::StrippedString)
  end
end
