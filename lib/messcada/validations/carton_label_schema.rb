# frozen_string_literal: true

module MesscadaApp
  class CartonLabelContract < Dry::Validation::Contract
    params do
      optional(:id).filled(:integer)
      required(:production_run_id).filled(:integer)
      required(:farm_id).filled(:integer)
      required(:puc_id).filled(:integer)
      required(:orchard_id).filled(:integer)
      required(:cultivar_group_id).filled(:integer)
      optional(:cultivar_id).maybe(:integer)
      required(:product_resource_allocation_id).maybe(:integer)
      required(:packhouse_resource_id).filled(:integer)
      required(:production_line_id).filled(:integer)
      required(:season_id).filled(:integer)
      required(:marketing_variety_id).filled(:integer)
      optional(:customer_variety_id).maybe(:integer)
      optional(:std_fruit_size_count_id).maybe(:integer)
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
      optional(:pm_bom_id).maybe(:integer)
      optional(:extended_columns).maybe(:hash)
      optional(:client_size_reference).maybe(Types::StrippedString)
      optional(:client_product_code).maybe(Types::StrippedString)
      optional(:treatment_ids).maybe(:array).maybe { each(:integer) }
      optional(:marketing_order_number).maybe(Types::StrippedString)
      optional(:fruit_sticker_pm_product_id).maybe(:integer)
      optional(:pm_type_id).maybe(:integer)
      optional(:pm_subtype_id).maybe(:integer)
      optional(:resource_id).maybe(:integer)
      optional(:label_name).maybe(Types::StrippedString)
      optional(:pick_ref).maybe(Types::StrippedString)
      required(:grade_id).filled(:integer)
      required(:product_chars).maybe(Types::StrippedString)
      required(:sell_by_code).maybe(Types::StrippedString)
      required(:pallet_label_name).maybe(Types::StrippedString)
      optional(:pallet_number).maybe(Types::StrippedString)
      optional(:phc).filled(Types::StrippedString)
      optional(:personnel_identifier_id).maybe(:integer)
      optional(:contract_worker_id).maybe(:integer)
      required(:packing_method_id).filled(:integer)
      optional(:target_market_id).maybe(:integer)
      optional(:marketing_puc_id).maybe(:integer)
      optional(:marketing_orchard_id).maybe(:integer)
      optional(:pm_mark_id).maybe(:integer)
      optional(:group_incentive_id).maybe(:integer)
      optional(:rmt_bin_id).maybe(:integer)
      optional(:dp_carton).maybe(:bool)
      optional(:gtin_code).maybe(Types::StrippedString)
      optional(:rmt_class_id).maybe(:integer)
      optional(:packing_specification_item_id).maybe(:integer)
      optional(:tu_labour_product_id).maybe(:integer)
      optional(:ru_labour_product_id).maybe(:integer)
      optional(:fruit_sticker_ids).maybe(:array).maybe { each(:integer) }
      optional(:tu_sticker_ids).maybe(:array).maybe { each(:integer) }
      optional(:target_customer_party_role_id).maybe(:integer)
      optional(:rmt_container_material_owner_id).maybe(:integer)
      optional(:legacy_data).maybe(:hash)
      optional(:colour_percentage_id).maybe(:integer)
      optional(:work_order_item_id).maybe(:integer)
      optional(:gross_weight).maybe(:decimal)
      optional(:actual_cold_treatment_id).maybe(:integer)
      optional(:actual_ripeness_treatment_id).maybe(:integer)
      optional(:rmt_code_id).maybe(:integer)
    end

    rule(:fruit_size_reference_id, :fruit_actual_counts_for_pack_id) do
      base.failure 'must provide either fruit_size_reference or fruit_actual_count' unless values[:fruit_size_reference_id] || values[:fruit_actual_counts_for_pack_id]
    end
  end

  # Validate a carton label weight against the min and max weights for the Commdity/Pack combination.
  class CartonLabelCheckWeightContract < Dry::Validation::Contract
    params do
      required(:pack_code).filled(:string)
      required(:commodity_code).filled(:string)
      required(:weight).filled(:decimal)
      required(:min_gross_weight).maybe(:decimal)
      required(:max_gross_weight).maybe(:decimal)
    end

    rule(:min_gross_weight) do
      base.failure "There is no min weight for #{values[:commodity_code]}/#{values[:pack_code]}" unless values[:min_gross_weight]
    end

    rule(:max_gross_weight) do
      base.failure "There is no max weight for #{values[:commodity_code]}/#{values[:pack_code]}" unless values[:max_gross_weight]
    end

    rule(:weight, :min_gross_weight) do
      key.failure "#{value.round(2).to_digits} is less than #{values[:min_gross_weight].round(2).to_digits} (min for #{values[:commodity_code]}/#{values[:pack_code]})" if values[:min_gross_weight] && values[:weight] < values[:min_gross_weight]
    end

    rule(:weight, :max_gross_weight) do
      key.failure "#{value.round(2).to_digits} is greater than #{values[:max_gross_weight].round(2).to_digits} (max for #{values[:commodity_code]}/#{values[:pack_code]})" if values[:max_gross_weight] && values[:weight] > values[:max_gross_weight]
    end
  end
end
