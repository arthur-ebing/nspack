# frozen_string_literal: true

module UiRules
  class OrchardTestTypeRule < Base
    def generate_rules
      @repo = QualityApp::OrchardTestRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields
      add_behaviours
      set_show_fields if %i[show reopen].include? @mode

      form_name 'orchard_test_type'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:test_type_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:applies_to_all_markets] = { renderer: :label, as_boolean: true }
      fields[:applies_to_all_cultivars] = { renderer: :label, as_boolean: true }
      fields[:applies_to_orchard] = { renderer: :label, as_boolean: true }
      fields[:applies_to_orchard_set] = { renderer: :label, as_boolean: true }
      fields[:allow_result_capturing] = { renderer: :label, as_boolean: true }
      fields[:pallet_level_result] = { renderer: :label, as_boolean: true }
      fields[:api_name] = { renderer: :label }
      fields[:result_type] = { renderer: :label }
      fields[:result_attributes] = { renderer: :label }
      fields[:applicable_tm_group_ids] = { renderer: :label,
                                           with_value: @form_object.applicable_tm_groups,
                                           caption: 'Target Market Groups' }
      fields[:applicable_cultivar_ids] = { renderer: :label,
                                           with_value: @form_object.applicable_cultivars,
                                           caption: 'Cultivars' }
      fields[:applicable_commodity_group_ids] = { renderer: :label,
                                                  with_value: @form_object.applicable_commodity_groups,
                                                  caption: 'Commodity Groups' }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        test_type_code: { required: true },
        description: {},
        applies_to_all_markets: { renderer: :checkbox },
        applies_to_all_cultivars: { renderer: :checkbox },
        applies_to_orchard: { renderer: :checkbox },
        applies_to_orchard_set: { renderer: :checkbox },
        allow_result_capturing: { renderer: :checkbox },
        pallet_level_result: { renderer: :checkbox },
        api_name: {},
        result_type: { renderer: :select,
                       options: AppConst::OMTC_RESULT_TYPE,
                       required: true },
        result_attributes: {},
        applicable_tm_group_ids: { renderer: :multi,
                                   options: MasterfilesApp::TargetMarketRepo.new.for_select_tm_groups,
                                   selected: @form_object.applicable_tm_group_ids,
                                   caption: 'Target Market Groups' },
        applicable_commodity_group_ids: { renderer: :multi,
                                          options: MasterfilesApp::CommodityRepo.new.for_select_commodity_groups,
                                          selected: @form_object.applicable_commodity_group_ids,
                                          caption: 'Commodity Groups' },
        applicable_cultivar_ids: { renderer: :multi,
                                   options: @repo.for_select_cultivars,
                                   selected: @form_object.applicable_cultivar_ids,
                                   caption: 'Cultivars' }
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
                                    applies_to_all_markets: false,
                                    applies_to_all_cultivars: false,
                                    applies_to_orchard: false,
                                    applies_to_orchard_set: false,
                                    allow_result_capturing: false,
                                    pallet_level_result: false,
                                    api_name: nil,
                                    result_type: nil,
                                    result_attributes: nil,
                                    applicable_tm_group_ids: [],
                                    applicable_cultivar_ids: [],
                                    applicable_commodity_group_ids: [])
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :applicable_commodity_group_ids, notify: [{ url: '/quality/config/orchard_test_types/commodity_group_changed' }] if %i[new edit].include? @mode
      end
    end
  end
end
