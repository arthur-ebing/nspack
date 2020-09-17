# frozen_string_literal: true

module EdiApp
  EdiFileUploadSchema = Dry::Schema.Params do
    required(:flow_type).filled(Types::StrippedString)
  end
end
