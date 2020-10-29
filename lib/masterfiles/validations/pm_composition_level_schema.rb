# frozen_string_literal: true

module MasterfilesApp
  PmCompositionLevelSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:composition_level).filled(:integer)
    required(:description).filled(Types::StrippedString)
  end
end
