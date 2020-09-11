# frozen_string_literal: true

module MasterfilesApp
  ScrapReasonSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:scrap_reason).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    optional(:applies_to_pallets).maybe(:bool)
    optional(:applies_to_bins).maybe(:bool)
  end
end
