# frozen_string_literal: true

module ProductionApp
  ProductSetupSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:product_setup_template_id, :integer).filled(:int?)
    required(:marketing_variety_id, :integer).filled(:int?)
    required(:customer_variety_variety_id, :integer).maybe(:int?)
    required(:std_fruit_size_count_id, :integer).maybe(:int?)
    required(:basic_pack_code_id, :integer).filled(:int?)
    required(:standard_pack_code_id, :integer).filled(:int?)
    required(:fruit_actual_counts_for_pack_id, :integer).maybe(:int?)
    required(:fruit_size_reference_id, :integer).maybe(:int?)
    required(:marketing_org_party_role_id, :integer).filled(:int?)
    required(:packed_tm_group_id, :integer).filled(:int?)
    required(:mark_id, :integer).filled(:int?)
    required(:inventory_code_id, :integer).maybe(:int?)
    required(:pallet_format_id, :integer).filled(:int?)
    required(:cartons_per_pallet_id, :integer).filled(:int?)
    required(:pm_bom_id, :integer).maybe(:int?)
    # required(:extended_columns, :hash).maybe(:hash?)
    required(:client_size_reference, Types::StrippedString).maybe(:str?)
    required(:client_product_code, Types::StrippedString).maybe(:str?)
    required(:treatment_ids, Types::IntArray).filled { each(:int?) }
    required(:marketing_order_number, Types::StrippedString).maybe(:str?)
    required(:sell_by_code, Types::StrippedString).maybe(:str?)
    required(:pallet_label_name, Types::StrippedString).maybe(:str?)
    required(:grade_id, :integer).maybe(:int?)
    required(:product_chars, Types::StrippedString).maybe(:str?)
    # required(:active, :bool).maybe(:bool?)
  end
end
