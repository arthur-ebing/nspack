# frozen_string_literal: true

module EdiApp
  EdiNsgtinInSchema = Dry::Schema.Params do
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
    required(:active).maybe(:bool)
    required(:marketing_org_party_role_id).maybe(:integer)
    required(:commodity_id).maybe(:integer)
    required(:marketing_variety_id).maybe(:integer)
    required(:standard_pack_code_id).maybe(:integer)
    required(:mark_id).maybe(:integer)
    required(:grade_id).maybe(:integer)
    required(:inventory_code_id).maybe(:integer)
    required(:fruit_actual_counts_for_pack_id).maybe(:integer)
    optional(:fruit_size_reference_id).maybe(:integer)
  end
end
