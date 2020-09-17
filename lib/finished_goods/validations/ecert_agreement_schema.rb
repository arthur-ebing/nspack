# frozen_string_literal: true

module FinishedGoodsApp
  EcertAgreementSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:code).filled(Types::StrippedString)
    required(:name).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:start_date).maybe(:date)
    required(:end_date).maybe(:date)
  end
end
