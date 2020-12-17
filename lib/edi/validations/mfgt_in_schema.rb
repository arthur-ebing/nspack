# frozen_string_literal: true

module EdiApp
  EdiMfgtInSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:transaction_number).filled(Types::StrippedString)
    required(:gtin_code).filled(Types::StrippedString)
    required(:date_to).maybe(:time)
    required(:date_from).maybe(:time)
    required(:org_code).maybe(Types::StrippedString)
    required(:commodity_code).maybe(Types::StrippedString)
    required(:marketing_variety_code).maybe(Types::StrippedString)
    required(:standard_pack_code).maybe(Types::StrippedString)
    required(:grade_code).maybe(Types::StrippedString)
    required(:mark_code).maybe(Types::StrippedString)
    required(:size_count_code).maybe(Types::StrippedString)
    required(:inventory_code).maybe(Types::StrippedString)
    required(:target_market_code).maybe(Types::StrippedString)
  end
end
