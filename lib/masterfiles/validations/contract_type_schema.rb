# frozen_string_literal: true

module MasterfilesApp
  ContractTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:contract_type_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
