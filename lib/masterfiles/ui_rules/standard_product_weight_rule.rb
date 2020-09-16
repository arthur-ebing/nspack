# frozen_string_literal: true

module UiRules
  class StandardProductWeightRule < Base
    def generate_rules
      @repo = MasterfilesApp::FruitSizeRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'standard_product_weight'
    end

    def set_show_fields  # rubocop:disable Metrics/AbcSize
      commodity_id_label = MasterfilesApp::CommodityRepo.new.find_commodity(@form_object.commodity_id)&.code
      standard_pack_id_label = MasterfilesApp::FruitSizeRepo.new.find_standard_pack_code(@form_object.standard_pack_id)&.standard_pack_code
      fields[:commodity_id] = { renderer: :label,
                                with_value: commodity_id_label,
                                caption: 'Commodity Code' }
      fields[:standard_pack_id] = { renderer: :label,
                                    with_value: standard_pack_id_label,
                                    caption: 'Standard Pack Code' }
      fields[:gross_weight] = { renderer: :label }
      fields[:nett_weight] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:standard_carton_nett_weight] = { renderer: :label }
      fields[:ratio_to_standard_carton] = { renderer: :label }
      fields[:is_standard_carton] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        commodity_id: { renderer: :select, options: MasterfilesApp::CommodityRepo.new.for_select_commodities,
                        disabled_options: MasterfilesApp::CommodityRepo.new.for_select_inactive_commodities,
                        caption: 'Commodity Code',
                        required: true },
        standard_pack_id: { renderer: :select, options: MasterfilesApp::FruitSizeRepo.new.for_select_standard_pack_codes,
                            disabled_options: MasterfilesApp::FruitSizeRepo.new.for_select_inactive_standard_pack_codes,
                            caption: 'Standard Pack Code',
                            required: true },
        gross_weight: { renderer: :numeric,
                        required: true },
        nett_weight: { renderer: :numeric,
                       required: true },
        standard_carton_nett_weight: { renderer: :numeric },
        ratio_to_standard_carton: { renderer: :numeric },
        is_standard_carton: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_standard_product_weight_flat(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(commodity_id: nil,
                                    standard_pack_id: nil,
                                    gross_weight: nil,
                                    nett_weight: nil,
                                    standard_carton_nett_weight: nil,
                                    ratio_to_standard_carton: nil,
                                    is_standard_carton: nil)
    end
  end
end
