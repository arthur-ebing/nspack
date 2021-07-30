# frozen_string_literal: true

module MasterfilesApp
  ColorPercentageSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:commodity_id).filled(:integer)
    required(:color_percentage).maybe(:integer, gteq?: 1, lteq?: 100)
    required(:description).filled(Types::StrippedString)
  end

  ColorPercentageInlineUpdateSchema = Dry::Schema.Params do
    required(:column_name).filled(Types::StrippedString)
    required(:column_value).maybe(:decimal, gteq?: 1, lteq?: 100)
  end
end
