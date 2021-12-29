# frozen_string_literal: true

module ProductionApp
  class ProductSetupContract < Dry::Validation::Contract
    params do
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
      optional(:rmt_class_id).maybe(:integer)
      optional(:standard_pack_code_id).maybe(:integer)
      required(:basic_pack_code_id).filled(:integer)
      optional(:target_customer_party_role_id).maybe(:integer)
      optional(:colour_percentage_id).maybe(:integer)
      required(:carton_label_template_id).maybe(:integer)
      optional(:rebin).maybe(:bool)
    end
    rule(:standard_pack_code_id) do
      key.failure 'must be filled' if values[:standard_pack_code_id].nil_or_empty? && !AppConst::CR_MF.basic_pack_equals_standard_pack?
    end
    # rule(:gtin_code) do
    #   base.failure 'GTIN Code not found' if AppConst::CR_PROD.use_gtins? && values[:gtin_code].nil_or_empty?
    # end
    rule(:fruit_actual_counts_for_pack_id, :fruit_size_reference_id) do
      key.failure 'Please choose either an Actual Count or Size Reference' if values[:fruit_size_reference_id].nil_or_empty? && values[:fruit_actual_counts_for_pack_id].nil_or_empty?
    end
  end

  class ProductSetupWizardFruitContract < Dry::Validation::Contract
    params do
      required(:product_setup_template_id).filled(:integer)
      required(:commodity_id).filled(:integer)
      required(:marketing_variety_id).filled(:integer)
      required(:std_fruit_size_count_id).maybe(:integer)
      required(:basic_pack_code_id).filled(:integer)
      required(:fruit_actual_counts_for_pack_id).maybe(:integer)
      optional(:standard_pack_code_id).maybe(:integer)
      required(:fruit_size_reference_id).maybe(:integer)
      required(:rmt_class_id).maybe(:integer)
      required(:grade_id).filled(:integer)
      optional(:colour_percentage_id).maybe(:integer)
      required(:rebin).maybe(:bool)
    end
    rule(:standard_pack_code_id) do
      key.failure 'must be filled' if values[:standard_pack_code_id].nil_or_empty? && !AppConst::CR_MF.basic_pack_equals_standard_pack?
    end
    rule(:fruit_size_reference_id, :fruit_actual_counts_for_pack_id) do
      key.failure 'Please choose either an Actual Count or Size Reference' if values[:fruit_size_reference_id].nil_or_empty? && values[:fruit_actual_counts_for_pack_id].nil_or_empty?
    end
  end

  class ProductSetupWizardMarketingContract < Dry::Validation::Contract
    params do
      required(:marketing_org_party_role_id).filled(:integer)
      required(:packed_tm_group_id).filled(:integer)
      required(:target_market_id).maybe(:integer)
      required(:sell_by_code).maybe(Types::StrippedString)
      required(:mark_id).filled(:integer)
      required(:product_chars).maybe(Types::StrippedString)
      required(:inventory_code_id).filled(:integer)
      required(:customer_variety_id).maybe(:integer)
      required(:client_product_code).maybe(Types::StrippedString)
      required(:client_size_reference).maybe(Types::StrippedString)
      required(:marketing_order_number).maybe(Types::StrippedString)
      optional(:gtin_code).maybe(Types::StrippedString)
    end
  end

  class ProductSetupWizardPackagingContract < Dry::Validation::Contract
    params do
      required(:pallet_format_id).filled(:integer)
      required(:pallet_label_name).maybe(Types::StrippedString)
      required(:cartons_per_pallet_id).filled(:integer)
      required(:carton_label_template_id).maybe(:integer)
    end
  end

  class ProductSetupWizardTreatmentContract < Dry::Validation::Contract
    params do
      optional(:treatment_ids).maybe(:array).maybe { each(:integer) }
    end
  end

  class ProductSetupWizardPackingSpecificationContract < Dry::Validation::Contract
    params do
      optional(:description).maybe(Types::StrippedString)
      required(:pm_bom_id).maybe(:integer)
      required(:pm_mark_id).maybe(:integer)
      optional(:product_setup_id).maybe(:integer)
      required(:tu_labour_product_id).maybe(:integer)
      required(:ru_labour_product_id).maybe(:integer)
      required(:ri_labour_product_id).maybe(:integer)
      required(:fruit_sticker_ids).maybe(:array).each(:integer) # OR: maybe(:array).maybe { each(:integer) } # if param can be nil (not [])
      required(:tu_sticker_ids).maybe(:array).each(:integer) # OR: maybe(:array).maybe { each(:integer) } # if param can be nil (not [])
      required(:ru_sticker_ids).maybe(:array).each(:integer) # OR: maybe(:array).maybe { each(:integer) } # if param can be nil (not [])
    end
  end
end
