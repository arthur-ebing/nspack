# frozen_string_literal: true

module MasterfilesApp
  PmSubtypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:pm_type_id).filled(:integer)
    required(:subtype_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
