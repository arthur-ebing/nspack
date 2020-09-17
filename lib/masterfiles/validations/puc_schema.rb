# frozen_string_literal: true

module MasterfilesApp
  PucSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:puc_code).filled(Types::StrippedString)
    required(:gap_code).maybe(Types::StrippedString)
  end
end
