# frozen_string_literal: true

module MesscadaApp
  CartonLabelSchema = Dry::Validation.Params do # rubocop:disable Metrics/BlockLength
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:production_run_id, :integer).filled(:int?)
    required(:farm_id, :integer).filled(:int?)
    required(:puc_id, :integer).filled(:int?)
    required(:orchard_id, :integer).filled(:int?)
    required(:cultivar_group_id, :integer).filled(:int?)
    required(:cultivar_id, :integer).maybe(:int?)
    required(:product_resource_allocation_id, :integer).filled(:int?)
    required(:packhouse_resource_id, :integer).filled(:int?)
    required(:production_line_id, :integer).filled(:int?)
    required(:season_id, :integer).filled(:int?)
    required(:marketing_variety_id, :integer).filled(:int?)
    required(:customer_variety_variety_id, :integer).maybe(:int?)
    required(:std_fruit_size_count_id, :integer).maybe(:int?)
    required(:basic_pack_code_id, :integer).filled(:int?)
    required(:standard_pack_code_id, :integer).filled(:int?)
    required(:fruit_actual_counts_for_pack_id, :integer).maybe(:int?)
    required(:fruit_size_reference_id, :integer).filled(:int?)
    required(:marketing_org_party_role_id, :integer).filled(:int?)
    required(:packed_tm_group_id, :integer).filled(:int?)
    required(:mark_id, :integer).filled(:int?)
    required(:inventory_code_id, :integer).filled(:int?)
    required(:pallet_format_id, :integer).filled(:int?)
    required(:cartons_per_pallet_id, :integer).filled(:int?)
    required(:pm_bom_id, :integer).maybe(:int?)
    optional(:extended_columns, :hash).maybe(:hash?)
    required(:client_size_reference, Types::StrippedString).maybe(:str?)
    required(:client_product_code, Types::StrippedString).maybe(:str?)
    required(:treatment_ids, Types::IntArray).filled { each(:int?) }
    required(:marketing_order_number, Types::StrippedString).maybe(:str?)
    required(:fruit_sticker_pm_product_id, :integer).maybe(:int?)
    required(:pm_type_id, :integer).maybe(:int?)
    required(:pm_subtype_id, :integer).maybe(:int?)
    required(:resource_id, :integer).maybe(:int?)
    required(:label_name, Types::StrippedString).maybe(:str?)
  end
end
