# frozen_string_literal: true

module EdiApp
  EdiPalbinInSchema = Dry::Validation.Params do
    configure { config.type_specs = true }
    required(:destination, Types::StrippedString).filled(:str?)
    required(:depot, Types::StrippedString).filled(:str?)
    required(:sscc, Types::StrippedString).filled(:str?)
    required(:farm, Types::StrippedString).filled(:str?)
    required(:puc, Types::StrippedString).filled(:str?)
    required(:orchard, Types::StrippedString).filled(:str?)
    required(:cultivar, Types::StrippedString).filled(:str?)
    required(:commodity, Types::StrippedString).filled(:str?)
    required(:grade, Types::StrippedString).filled(:str?)
    required(:pack, Types::StrippedString).filled(:str?)
    required(:size_reference, Types::StrippedString).filled(:str?)
    required(:shipped_at, %i[nil time]).filled(:time?)
    required(:gross_weight, %i[nil decimal]).filled(:decimal?)
    required(:nett_weight, %i[nil decimal]).filled(:decimal?)
  end
end
