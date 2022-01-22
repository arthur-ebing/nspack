# frozen_string_literal: true

module EdiApp
  NsrunHeaderSchema = Dry::Schema.Params do
    required(:run_batch_number).filled(Types::StrippedString)
    required(:packhouse_code).filled(Types::StrippedString)
    required(:line_code).filled(Types::StrippedString)
    required(:farm_code).filled(Types::StrippedString)
    required(:puc_code).filled(Types::StrippedString)
    required(:season_code).filled(Types::StrippedString)
    required(:orchard_code).filled(Types::StrippedString)
    required(:cultivar_group_code).filled(Types::StrippedString)
    required(:cultivar_code).maybe(Types::StrippedString)
    required(:lot_no_date).maybe(:date)
    required(:rmt_code).maybe(Types::StrippedString)
    required(:rmt_size_code).maybe(Types::StrippedString)
  end

  class NsrunContract < Dry::Validation::Contract
    option :requires_standard_counts

    params do
      required(:marketing_variety).filled(Types::StrippedString)
      required(:std_fruit_size_count).maybe(:integer)
      required(:basic_pack_code).maybe(Types::StrippedString)
      required(:standard_pack_code).filled(Types::StrippedString)
      required(:actual_count).maybe(:integer)
      required(:fruit_size_reference).maybe(Types::StrippedString)
      required(:marketing_org_code).filled(Types::StrippedString)
      required(:packed_tm_group).filled(Types::StrippedString)
      required(:mark_code).filled(Types::StrippedString)
      required(:inventory_code).filled(Types::StrippedString)
      required(:grade_code).filled(Types::StrippedString)
      required(:target_market_code).maybe(Types::StrippedString)
      required(:gtin_code).maybe(Types::StrippedString)
      required(:pallet_base).filled(Types::StrippedString)
      required(:pallet_stack_type).filled(Types::StrippedString)
      required(:cartons_per_pallet).filled(:integer)
      required(:client_size_reference).maybe(Types::StrippedString)
      required(:client_product_code).maybe(Types::StrippedString)
      required(:treatment_ids).maybe(Types::StrippedString)
      required(:marketing_order_number).maybe(Types::StrippedString)
      required(:sell_by_code).maybe(Types::StrippedString)
      required(:product_chars).maybe(Types::StrippedString)
      required(:rmt_class_code).maybe(Types::StrippedString)
      required(:target_customer_code).maybe(Types::StrippedString)
      required(:colour_percentage_code).maybe(Types::StrippedString)
      required(:carton_label_template).maybe(Types::StrippedString)
      required(:rebin).maybe(Types::StrippedString)
    end

    rule(:basic_pack_code) do
      key.failure('must be provided') if AppConst::CR_MF.basic_pack_equals_standard_pack? && value.nil?
    end

    rule(:std_fruit_size_count) do
      key.failure('must be provided') if requires_standard_counts && value.nil?
    end

    rule(:actual_count) do
      key.failure('must be provided') if requires_standard_counts && value.nil?
    end

    rule(:fruit_size_reference) do
      key.failure('must be provided') if value.nil? && !requires_standard_counts
    end

    rule(:rebin) do
      key.failure('must be Y or N (or left blank)') if value && !%w[Y N].include?(value)
    end

    rule(:treatment_ids) do
      key.failure('must be a comma-separated list of integer ids') if value && !value.match(/^[\d,]+$/)
    end
  end
end
