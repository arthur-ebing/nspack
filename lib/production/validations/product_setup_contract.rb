# frozen_string_literal: true

module ProductionApp
  class ProductSetupContract < Dry::Validation::Contract
    params do # rubocop:disable Metrics/BlockLength
      optional(:id).filled(:integer)
      required(:product_setup_template_id).filled(:integer)
      required(:marketing_variety_id).filled(:integer)
      required(:customer_variety_id).maybe(:integer)
      required(:std_fruit_size_count_id).maybe(:integer)
      required(:fruit_actual_counts_for_pack_id).maybe(:integer)
      required(:fruit_size_reference_id).maybe(:integer)
      required(:marketing_org_party_role_id).filled(:integer)
      required(:packed_tm_group_id).filled(:integer)
      required(:mark_id).filled(:integer)
      required(:inventory_code_id).filled(:integer)
      required(:pallet_format_id).filled(:integer)
      required(:cartons_per_pallet_id).filled(:integer)
      required(:client_size_reference).maybe(Types::StrippedString)
      required(:client_product_code).maybe(Types::StrippedString)
      optional(:treatment_ids).maybe(:array).maybe { each(:integer) }
      required(:marketing_order_number).maybe(Types::StrippedString)
      required(:sell_by_code).maybe(Types::StrippedString)
      required(:pallet_label_name).maybe(Types::StrippedString)
      required(:grade_id).filled(:integer)
      required(:product_chars).maybe(Types::StrippedString)
      required(:target_market_id).maybe(:integer)
      optional(:gtin_code).maybe(Types::StrippedString)
      required(:rmt_class_id).maybe(:integer)
      optional(:standard_pack_code_id).maybe(:integer)
      required(:basic_pack_code_id).filled(:integer)
    end
    rule(:standard_pack_code_id) do
      key.failure 'must be filled' if values[:basic_pack_code_id].nil_or_empty? && !AppConst::CR_MF.basic_pack_equals_standard_pack?
    end
    rule(:gtin_code) do
      base.failure 'GTIN Code not found' if AppConst::CR_PROD.use_gtins? && values[:gtin_code].nil_or_empty?
    end
    rule(:fruit_actual_counts_for_pack_id, :fruit_size_reference_id) do
      key.failure 'Please choose either an Actual Count or Size Reference' if values[:fruit_size_reference_id].nil_or_empty? && values[:fruit_actual_counts_for_pack_id].nil_or_empty?
    end
  end
end
