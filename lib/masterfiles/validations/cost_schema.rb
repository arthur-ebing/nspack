# frozen_string_literal: true

module MasterfilesApp
  CostSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:cost_type_id).filled(:integer)
    required(:cost_code).filled(Types::StrippedString)
    required(:default_amount).maybe(:decimal)
    optional(:description).maybe(Types::StrippedString)
  end
end
