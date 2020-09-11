# frozen_string_literal: true

module EdiApp
  EdiOutTransactionSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:flow_type).filled(Types::StrippedString)
    required(:org_code).filled(Types::StrippedString)
    required(:hub_address).filled(Types::StrippedString)
    required(:user_name).filled(Types::StrippedString)
    required(:complete).maybe(:bool)
    required(:edi_out_filename).maybe(Types::StrippedString)
    required(:record_id).maybe(:integer)
    required(:error_message).maybe(Types::StrippedString)
  end
end
