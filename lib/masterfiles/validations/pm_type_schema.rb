# frozen_string_literal: true

module MasterfilesApp
  PmTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:pm_type_code).filled(Types::StrippedString)
    required(:description).filled(Types::StrippedString)
  end

  ExtendedPmTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:pm_type_code).filled(Types::StrippedString)
    required(:description).filled(Types::StrippedString)
    required(:pm_composition_level_id).filled(:integer)
    required(:short_code).maybe(Types::StrippedString)
  end
end
