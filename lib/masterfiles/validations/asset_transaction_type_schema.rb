# frozen_string_literal: true

module MasterfilesApp
  AssetTransactionTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:transaction_type_code).filled(Types::StrippedString)
    required(:description).filled(Types::StrippedString)
  end
end
