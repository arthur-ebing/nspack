# frozen_string_literal: true

module MasterfilesApp
  RegisteredOrchardSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:orchard_code).filled(Types::StrippedString)
    required(:cultivar_code).filled(Types::StrippedString)
    required(:puc_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:marketing_orchard).maybe(:bool)
  end
end
