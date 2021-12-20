# frozen_string_literal: true

module MasterfilesApp
  RmtClassificationSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:rmt_classification_type_id).filled(:integer)
    required(:rmt_classification).filled(Types::StrippedString)
  end
end
