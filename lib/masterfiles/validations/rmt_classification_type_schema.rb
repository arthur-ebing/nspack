# frozen_string_literal: true

module MasterfilesApp
  RmtClassificationTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:rmt_classification_type_code).filled(Types::StrippedString)
    optional(:description).maybe(Types::StrippedString)
    optional(:required_for_delivery).maybe(:bool)
    optional(:physical_attribute).maybe(:bool)
  end
end
