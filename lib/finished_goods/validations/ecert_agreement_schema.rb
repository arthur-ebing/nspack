# frozen_string_literal: true

module FinishedGoodsApp
  EcertAgreementSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:code, Types::StrippedString).filled(:str?)
    required(:name, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).maybe(:str?)
    required(:start_date, %i[nil date]).maybe(:date?)
    required(:end_date, %i[nil date]).maybe(:date?)
  end
end
