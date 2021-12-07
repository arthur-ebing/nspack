# frozen_string_literal: true

module MasterfilesApp
  ColourPercentageSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:commodity_id).filled(:integer)
    required(:colour_percentage).maybe(Types::StrippedString)
    required(:description).filled(Types::StrippedString)
  end

  ColourPercentageInlineUpdateSchema = Dry::Schema.Params do
    required(:column_name).filled(Types::StrippedString)
    required(:column_value).maybe(Types::StrippedString)
  end
end
