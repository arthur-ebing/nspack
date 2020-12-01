# frozen_string_literal: true

module ProductionApp
  ProductSetupSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:product_setup_template_id).filled(:integer)
    required(:marketing_variety_id).filled(:integer)
    required(:customer_variety_id).maybe(:integer)
    required(:std_fruit_size_count_id).maybe(:integer)
    required(:basic_pack_code_id).filled(:integer)
    required(:standard_pack_code_id).filled(:integer)
    required(:fruit_actual_counts_for_pack_id).maybe(:integer)
    required(:fruit_size_reference_id).maybe(:integer)
    required(:marketing_org_party_role_id).filled(:integer)
    required(:packed_tm_group_id).filled(:integer)
    required(:mark_id).filled(:integer)
    required(:inventory_code_id).filled(:integer)
    required(:pallet_format_id).filled(:integer)
    required(:cartons_per_pallet_id).filled(:integer)
    required(:pm_bom_id).maybe(:integer)
    # required(:extended_columns).maybe(:hash)
    required(:client_size_reference).maybe(Types::StrippedString)
    required(:client_product_code).maybe(Types::StrippedString)
    optional(:treatment_ids).maybe(:array).maybe { each(:integer) }
    required(:marketing_order_number).maybe(Types::StrippedString)
    required(:sell_by_code).maybe(Types::StrippedString)
    required(:pallet_label_name).maybe(Types::StrippedString)
    required(:grade_id).filled(:integer)
    required(:product_chars).maybe(Types::StrippedString)
    # required(:active).maybe(:bool)
    required(:target_market_id).maybe(:integer)
  end
end
