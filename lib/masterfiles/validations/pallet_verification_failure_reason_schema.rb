# frozen_string_literal: true

module MasterfilesApp
  PalletVerificationFailureReasonSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:reason).filled(Types::StrippedString)
  end
end
