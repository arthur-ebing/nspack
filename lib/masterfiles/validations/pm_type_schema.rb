# frozen_string_literal: true

module MasterfilesApp
  PmTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:pm_type_code).filled(Types::StrippedString)
    required(:description).filled(Types::StrippedString)
    optional(:pm_composition_level_id).maybe(:integer)
    optional(:short_code).maybe(Types::StrippedString)
  end
end
