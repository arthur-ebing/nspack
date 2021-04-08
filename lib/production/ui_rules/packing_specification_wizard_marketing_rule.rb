# frozen_string_literal: true

module UiRules
  class PackingSpecificationWizardMarketingRule < Base
    def generate_rules
      form_name 'packing_specification_wizard'

      common_values_for_fields common_fields
      make_header_table
      add_behaviours
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      make_form_object
      {
        marketing_org_party_role_id: { renderer: :select,
                                       options: @party_repo.for_select_party_roles(AppConst::ROLE_MARKETER),
                                       selected: @form_object.marketing_org_party_role_id,
                                       prompt: true,
                                       required: true,
                                       caption: 'Marketing Org' },
        packed_tm_group_id: { renderer: :select,
                              options: @target_repo.for_select_packed_tm_groups,
                              disabled_options: @target_repo.for_select_inactive_tm_groups,
                              prompt: true,
                              required: true,
                              caption: 'Packed TM Group' },
        target_market_id: { renderer: :select,
                            options: @target_repo.for_select_packed_group_tms(
                              where: { target_market_group_id: @form_object.packed_tm_group_id }
                            ),
                            disabled_options: @target_repo.for_select_inactive_target_markets,
                            prompt: true,
                            caption: 'Target Market' },
        sell_by_code: {},
        mark_id: { renderer: :select,
                   options: @marketing_repo.for_select_marks,
                   disabled_options: @marketing_repo.for_select_inactive_marks,
                   prompt: true,
                   required: true,
                   caption: 'Mark' },
        product_chars: {},
        inventory_code_id: { renderer: :select,
                             options: @fruit_repo.for_select_inventory_codes,
                             disabled_options: @fruit_repo.for_select_inactive_inventory_codes,
                             prompt: true,
                             required: true,
                             caption: 'Inventory Code'  },
        customer_variety_id: { renderer: :select,
                               options: @marketing_repo.for_select_customer_varieties(
                                 where: { packed_tm_group_id: @form_object.packed_tm_group_id,
                                          marketing_variety_id: @form_object.marketing_variety_id }
                               ),
                               disabled_options: @marketing_repo.for_select_inactive_customer_varieties,
                               prompt: true,
                               caption: 'Customer Variety' },
        client_product_code: {},
        client_size_reference: {},
        marketing_order_number: {}
      }
    end

    def make_form_object
      @repo = ProductionApp::PackingSpecificationRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      @fruit_repo = MasterfilesApp::FruitRepo.new
      @target_repo = MasterfilesApp::TargetMarketRepo.new
      @marketing_repo = MasterfilesApp::MarketingRepo.new

      apply_form_values

      @form_object[:marketing_org_party_role_id] ||= @party_repo.find_party_role_from_party_name_for_role(AppConst::CR_PROD.default_marketing_org, AppConst::ROLE_MARKETER)
    end

    def make_header_table
      form_object_merge!(@repo.extend_packing_specification(@form_object))
      compact_header(UtilityFunctions.symbolize_keys(@form_object.compact_header))
    end

    def handle_behaviour
      changed = {
        packed_tm_group: :packed_tm_group_changed
      }
      changed = changed[@options[:field]]
      return unhandled_behaviour! if changed.nil?

      send(changed)
    end

    private

    def add_behaviours
      url = "/production/packing_specifications/wizard/change/packing_specification_wizard_marketing/#{@mode}"
      behaviours do |behaviour|
        behaviour.dropdown_change :packed_tm_group_id,
                                  notify: [{ url: "#{url}/packed_tm_group",
                                             param_keys: %i[packing_specification_wizard_marketing_variety_id] }]
      end
    end

    def packed_tm_group_changed # rubocop:disable Metrics/AbcSize
      form_object_merge!(params)
      @form_object[:packed_tm_group_id] = params[:changed_value].to_i
      @form_object[:marketing_variety_id] = params[:packing_specification_wizard_marketing_variety_id].to_i
      fields = common_fields

      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packing_specification_wizard_customer_variety_id',
                                   options_array: fields[:customer_variety_id][:options]),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packing_specification_wizard_target_market_id',
                                   options_array: fields[:target_market_id][:options])])
    end
  end
end
