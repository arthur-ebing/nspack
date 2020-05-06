# frozen_string_literal: true

module UiRules
  class OrchardTestTypeRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = QualityApp::OrchardTestRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields
      add_behaviours if %i[new edit].include? @mode
      set_show_fields if %i[show reopen].include? @mode

      form_name 'orchard_test_type'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:test_type_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:applies_to_all_markets] = { renderer: :label, as_boolean: true,
                                          hide_on_load: !@form_object.applies_to_all_markets }
      fields[:applies_to_all_cultivars] = { renderer: :label, as_boolean: true,
                                            hide_on_load: !@form_object.applies_to_all_cultivars }
      fields[:applies_to_orchard] = { renderer: :label, as_boolean: true }
      fields[:allow_result_capturing] = { renderer: :label, as_boolean: true }
      fields[:pallet_level_result] = { renderer: :label, as_boolean: true }
      fields[:applicable_tm_group_ids] = { renderer: :label,
                                           with_value: @form_object.applicable_tm_groups,
                                           hide_on_load: @form_object.applies_to_all_markets,
                                           caption: 'Target Market Groups' }
      fields[:applicable_cultivar_ids] = { renderer: :label,
                                           with_value: @form_object.applicable_cultivars,
                                           hide_on_load: @form_object.applies_to_all_cultivars,
                                           caption: 'Cultivars' }
      fields[:applicable_commodity_group_ids] = { renderer: :label,
                                                  with_value: @form_object.applicable_commodity_groups,
                                                  hide_on_load: @form_object.applies_to_all_cultivars,
                                                  caption: 'Commodity Groups' }
      fields[:result_type] = { renderer: :label }
      fields[:api_name] = { renderer: :label }
      api_attribute_value = @repo.get_value(:orchard_test_api_attributes, :description, api_attribute: @form_object.api_attribute)
      fields[:api_attribute] = { renderer: :label,
                                 with_value: api_attribute_value,
                                 hide_on_load: @form_object.api_name.nil_or_empty? }
      fields[:api_pass_result] = { renderer: :label,
                                   caption: 'Pass Value' }
      fields[:api_default_result] = { renderer: :label,
                                      caption: 'Default Value' }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      {
        test_type_code: { required: true,
                          force_uppercase: true },
        description: {},
        applies_to_all_markets: { renderer: :checkbox },
        applies_to_all_cultivars: { renderer: :checkbox },
        applies_to_orchard: { renderer: :checkbox },
        allow_result_capturing: { renderer: :checkbox },
        pallet_level_result: { renderer: :checkbox },
        result_type: { renderer: :select,
                       options: AppConst::QUALITY_RESULT_TYPE,
                       prompt: true,
                       required: true },
        applicable_tm_group_ids: { renderer: :multi,
                                   options: MasterfilesApp::TargetMarketRepo.new.for_select_tm_groups,
                                   selected: @form_object.applicable_tm_group_ids,
                                   hide_on_load: @form_object.applies_to_all_markets,
                                   caption: 'Target Market Groups' },
        applicable_commodity_group_ids: { renderer: :multi,
                                          options: MasterfilesApp::CommodityRepo.new.for_select_commodity_groups,
                                          selected: @form_object.applicable_commodity_group_ids,
                                          hide_on_load: @form_object.applies_to_all_cultivars,
                                          caption: 'Commodity Groups' },
        applicable_cultivar_ids: { renderer: :multi,
                                   options: @repo.for_select_cultivar_codes,
                                   selected: @form_object.applicable_cultivar_ids,
                                   hide_on_load: @form_object.applies_to_all_cultivars,
                                   caption: 'Cultivars' },
        api_name: { renderer: :select,
                    options: AppConst::QUALITY_API_NAMES,
                    selected: @form_object.api_name,
                    prompt: true },
        api_attribute: { renderer: :select,
                         options: @repo.for_select_orchard_test_api_attributes(@form_object.api_name),
                         selected: @form_object.api_name.nil_or_empty? },
        api_pass_result: { caption: 'Pass Value',
                           required: @form_object.result_type != AppConst::CLASSIFICATION,
                           hide_on_load: @form_object.result_type == AppConst::CLASSIFICATION },
        api_default_result: { caption: 'Default Value' }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_orchard_test_type_flat(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(test_type_code: nil,
                                    description: nil,
                                    applies_to_all_markets: true,
                                    applies_to_all_cultivars: true,
                                    applies_to_orchard: false,
                                    allow_result_capturing: false,
                                    pallet_level_result: false,
                                    api_name: nil,
                                    result_type: AppConst::CLASSIFICATION,
                                    api_attribute: nil,
                                    api_pass_result: nil,
                                    api_default_result: nil,
                                    applicable_tm_group_ids: [],
                                    applicable_cultivar_ids: [],
                                    applicable_commodity_group_ids: [])
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :applicable_commodity_group_ids, notify: [{ url: '/quality/config/orchard_test_types/commodity_group_changed' }]
        behaviour.dropdown_change :api_name, notify: [{ url: '/quality/config/orchard_test_types/api_name_changed' }]
        behaviour.dropdown_change :result_type, notify: [{ url: '/quality/config/orchard_test_types/result_type_changed' }]
        behaviour.input_change :applies_to_all_markets, notify: [{ url: '/quality/config/orchard_test_types/applies_to_all_markets' }]
        behaviour.input_change :applies_to_all_cultivars, notify: [{ url: '/quality/config/orchard_test_types/applies_to_all_cultivars' }]
      end
    end
  end
end
