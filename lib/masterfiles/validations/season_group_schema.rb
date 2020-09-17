# frozen_string_literal: true

module MasterfilesApp
  SeasonGroupSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:season_group_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:season_group_year).maybe(:integer)
  end
end
