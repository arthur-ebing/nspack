# frozen_string_literal: true

module EdiApp
  EdiOutTransactionSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:flow_type, Types::StrippedString).filled(:str?)
    required(:org_code, Types::StrippedString).filled(:str?)
    required(:hub_address, Types::StrippedString).filled(:str?)
    required(:user_name, Types::StrippedString).filled(:str?)
    required(:complete, :bool).maybe(:bool?)
    required(:edi_out_filename, Types::StrippedString).maybe(:str?)
    required(:record_id, :integer).maybe(:int?)
    required(:error_message, Types::StrippedString).maybe(:str?)
  end
end
