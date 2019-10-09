# frozen_string_literal: true

module MasterfilesApp
  PalletVerificationFailureReasonSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:reason, Types::StrippedString).filled(:str?)
  end
end
