# frozen_string_literal: true

module MasterfilesApp
  PucSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:puc_code).filled(Types::StrippedString)
    required(:gap_code).maybe(Types::StrippedString)
    required(:gap_code_valid_from).maybe(:time)
    required(:gap_code_valid_until).maybe(:time)
  end
end
