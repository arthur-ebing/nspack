# frozen_string_literal: true

module MasterfilesApp
  ScrapReasonSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:scrap_reason, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).maybe(:str?)
    optional(:applies_to_pallets, :bool).maybe(:bool?)
    optional(:applies_to_bins, :bool).maybe(:bool?)
  end
end
