# frozen_string_literal: true

module MasterfilesApp
  RmtHandlingRegimeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:regime_code).filled(Types::StrippedString)
    optional(:description).maybe(Types::StrippedString)
    required(:for_packing).maybe(:bool)
  end
end
