# frozen_string_literal: true

module MasterfilesApp
  RegistrationSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:party_id).filled(:integer)
    required(:registration_type).filled(Types::StrippedString)
    required(:registration_code).filled(Types::StrippedString)
  end
end
