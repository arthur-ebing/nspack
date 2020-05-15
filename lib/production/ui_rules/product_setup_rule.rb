# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
# frozen_string_literal: true

module UiRules
  class ProductSetupRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = ProductionApp::ProductSetupRepo.new
      make_form_object
      apply_form_values

      @rules[:hide_some_fields] = (AppConst::CLIENT_CODE == 'kr')
      @rules[:require_packaging_bom] = AppConst::REQUIRE_PACKAGING_BOM

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      add_behaviours if %i[new edit].include? @mode

      form_name 'product_setup'
    end

    def set_show_fields  # rubocop:disable Metrics/AbcSize
      product_setup_template_id_label = @repo.find_hash(:product_setup_templates, @form_object.product_setup_template_id)[:template_name]
      marketing_variety_id_label = @repo.find_hash(:marketing_varieties, @form_object.marketing_variety_id)[:marketing_variety_code]
      customer_variety_id_label = MasterfilesApp::MarketingRepo.new.find_customer_variety(@form_object.customer_variety_id)&.variety_as_customer_variety
      std_fruit_size_count_id_label = MasterfilesApp::FruitSizeRepo.new.find_std_fruit_size_count(@form_object.std_fruit_size_count_id)&.size_count_value
      basic_pack_code_id_label = @repo.find_hash(:basic_pack_codes, @form_object.basic_pack_code_id)[:basic_pack_code]
      standard_pack_code_id_label = @repo.find_hash(:standard_pack_codes, @form_object.standard_pack_code_id)[:standard_pack_code]
      fruit_actual_counts_for_pack_id_label = MasterfilesApp::FruitSizeRepo.new.find_fruit_actual_counts_for_pack(@form_object.fruit_actual_counts_for_pack_id)&.actual_count_for_pack
      fruit_size_reference_id_label = MasterfilesApp::FruitSizeRepo.new.find_fruit_size_reference(@form_object.fruit_size_reference_id)&.size_reference
      marketing_org_party_role_id_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.marketing_org_party_role_id)&.party_name
      packed_tm_group_id_label = @repo.find_hash(:target_market_groups, @form_object.packed_tm_group_id)[:target_market_group_name]
      mark_id_label = @repo.find_hash(:marks, @form_object.mark_id)[:mark_code]
      inventory_code_id_label = MasterfilesApp::FruitRepo.new.find_inventory_code(@form_object.inventory_code_id)&.inventory_code
      pallet_format_id_label = @repo.find_hash(:pallet_formats, @form_object.pallet_format_id)[:description]
      cartons_per_pallet_id_label = @repo.find_hash(:cartons_per_pallet, @form_object.cartons_per_pallet_id)[:cartons_per_pallet]
      pm_bom_id_label = MasterfilesApp::BomsRepo.new.find_pm_bom(@form_object.pm_bom_id)&.bom_code
      commodity_id_label = MasterfilesApp::CommodityRepo.new.find_commodity(@form_object.commodity_id)&.code
      grade_id_label = MasterfilesApp::FruitRepo.new.find_grade(@form_object.grade_id)&.grade_code
      pallet_base_id_label = MasterfilesApp::PackagingRepo.new.find_pallet_base(@form_object.pallet_base_id)&.pallet_base_code
      pallet_stack_type_id_label = MasterfilesApp::PackagingRepo.new.find_pallet_stack_type(@form_object.pallet_stack_type_id)&.stack_type_code
      pm_type_id_label = MasterfilesApp::BomsRepo.new.find_pm_type(@form_object.pm_type_id)&.pm_type_code
      pm_subtype_id_label = MasterfilesApp::BomsRepo.new.find_pm_subtype(@form_object.pm_subtype_id)&.subtype_code
      fields[:product_setup_template_id] = { renderer: :label, with_value: product_setup_template_id_label, caption: 'Product Setup Template' }
      fields[:marketing_variety_id] = { renderer: :label, with_value: marketing_variety_id_label, caption: 'Marketing Variety' }
      fields[:customer_variety_id] = { renderer: :label, with_value: customer_variety_id_label, caption: 'Customer Variety' }
      fields[:std_fruit_size_count_id] = { renderer: :label, with_value: std_fruit_size_count_id_label, caption: 'Std Fruit Size Count' }
      fields[:basic_pack_code_id] = { renderer: :label, with_value: basic_pack_code_id_label, caption: 'Basic Pack Code' }
      fields[:standard_pack_code_id] = { renderer: :label, with_value: standard_pack_code_id_label, caption: 'Standard Pack Code', hide_on_load: @rules[:hide_some_fields] ? true : false }
      fields[:fruit_actual_counts_for_pack_id] = { renderer: :label, with_value: fruit_actual_counts_for_pack_id_label, caption: 'Actual Count' }
      fields[:fruit_size_reference_id] = { renderer: :label, with_value: fruit_size_reference_id_label, caption: 'Size Reference' }
      fields[:marketing_org_party_role_id] = { renderer: :label, with_value: marketing_org_party_role_id_label, caption: 'Marketing Org Party Role' }
      fields[:packed_tm_group_id] = { renderer: :label, with_value: packed_tm_group_id_label, caption: 'Packed Tm Group' }
      fields[:mark_id] = { renderer: :label, with_value: mark_id_label, caption: 'Mark' }
      fields[:inventory_code_id] = { renderer: :label, with_value: inventory_code_id_label, caption: 'Inventory Code' }
      fields[:pallet_format_id] = { renderer: :label, with_value: pallet_format_id_label, caption: 'Pallet Format' }
      fields[:cartons_per_pallet_id] = { renderer: :label, with_value: cartons_per_pallet_id_label, caption: 'Cartons Per Pallet' }
      fields[:pm_bom_id] = { renderer: :label, with_value: pm_bom_id_label, caption: 'Pm Bom', hide_on_load: @rules[:require_packaging_bom] ? false : true }
      fields[:extended_columns] = { renderer: :label }
      fields[:client_size_reference] = { renderer: :label }
      fields[:client_product_code] = { renderer: :label }
      fields[:marketing_order_number] = { renderer: :label }
      fields[:sell_by_code] = { renderer: :label }
      fields[:pallet_label_name] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:treatment_ids] = { renderer: :list, items: treatment_codes, caption: 'Treatments', hide_on_load: @rules[:hide_some_fields] ? true : false  }
      fields[:commodity_id] = { renderer: :label, with_value: commodity_id_label, caption: 'Commodity' }
      fields[:grade_id] = { renderer: :label, with_value: grade_id_label, caption: 'Grade' }
      fields[:pallet_base_id] = { renderer: :label, with_value: pallet_base_id_label, caption: 'Pallet Base' }
      fields[:pallet_stack_type_id] = { renderer: :label, with_value: pallet_stack_type_id_label, caption: 'Pallet Stack Type' }
      fields[:pm_type_id] = { renderer: :label, with_value: pm_type_id_label, caption: 'PM Type', hide_on_load: @rules[:require_packaging_bom] ? false : true }
      fields[:pm_subtype_id] = { renderer: :label, with_value: pm_subtype_id_label, caption: 'PM Subtype', hide_on_load: @rules[:require_packaging_bom] ? false : true }
      fields[:description] = { renderer: :label, hide_on_load: @rules[:require_packaging_bom] ? false : true }
      fields[:erp_bom_code] = { renderer: :label, hide_on_load: @rules[:require_packaging_bom] ? false : true }
      fields[:product_chars] = { renderer: :label }
    end

    def common_fields  # rubocop:disable Metrics/AbcSize
      product_setup_template_id = @options[:product_setup_template_id].nil_or_empty? ? @repo.find_product_setup(@options[:id]).product_setup_template_id : @options[:product_setup_template_id]
      product_setup_template = @repo.find_product_setup_template(product_setup_template_id)
      product_setup_template_id_label = product_setup_template&.template_name
      cultivar_group_id = product_setup_template&.cultivar_group_id
      cultivar_id = product_setup_template&.cultivar_id
      commodity_id = @form_object[:commodity_id].nil_or_empty? ? @repo.commodity_id(cultivar_group_id, cultivar_id) : @form_object[:commodity_id]
      default_mkting_org_id = @form_object[:marketing_org_party_role_id].nil_or_empty? ? MasterfilesApp::PartyRepo.new.find_party_role_from_party_name_for_role(AppConst::DEFAULT_MARKETING_ORG, AppConst::ROLE_MARKETER) : @form_object[:marketing_org_party_role_id]

      default_pm_type_id = @form_object[:pm_type_id].nil_or_empty? ? MasterfilesApp::BomsRepo.new.find_pm_type(DB[:pm_types].where(pm_type_code: AppConst::DEFAULT_FG_PACKAGING_TYPE).select_map(:id))&.id : @form_object[:pm_type_id]
      customer_varieties = if @form_object.packed_tm_group_id.nil_or_empty? || @form_object.marketing_variety_id.nil_or_empty?
                             []
                           else
                             MasterfilesApp::MarketingRepo.new.for_select_customer_varieties(@form_object.packed_tm_group_id, @form_object.marketing_variety_id)
                           end
      pm_boms = if @form_object.pm_subtype_id.nil_or_empty?
                  []
                else
                  MasterfilesApp::BomsRepo.new.for_select_pm_subtype_pm_boms(@form_object.pm_subtype_id)
                end
      {
        product_setup_template: { renderer: :label, with_value: product_setup_template_id_label, caption: 'Product Setup Template', readonly: true },
        product_setup_template_id: { renderer: :hidden, value: product_setup_template_id },
        commodity_id: { renderer: :select,
                        options: @repo.for_select_template_cultivar_commodities(cultivar_group_id, cultivar_id),
                        disabled_options: MasterfilesApp::CommodityRepo.new.for_select_inactive_commodities,
                        caption: 'Commodity',
                        required: true,
                        searchable: true,
                        remove_search_for_small_list: false },
        marketing_variety_id: { renderer: :select,
                                options: @repo.for_select_template_commodity_marketing_varieties(product_setup_template_id, commodity_id),
                                disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_marketing_varieties,
                                caption: 'Marketing Variety',
                                required: true,
                                prompt: 'Select Marketing Variety',
                                searchable: true,
                                remove_search_for_small_list: false },
        std_fruit_size_count_id: { renderer: :select,
                                   options: MasterfilesApp::FruitSizeRepo.new.for_select_std_fruit_size_counts(where: { commodity_id: commodity_id }),
                                   disabled_options: MasterfilesApp::FruitSizeRepo.new.for_select_inactive_std_fruit_size_counts,
                                   caption: 'Std Size Count',
                                   prompt: 'Select Size Count',
                                   searchable: true,
                                   remove_search_for_small_list: false },
        basic_pack_code_id: { renderer: :select,
                              options: MasterfilesApp::FruitSizeRepo.new.for_select_basic_pack_codes,
                              disabled_options: MasterfilesApp::FruitSizeRepo.new.for_select_inactive_basic_pack_codes,
                              caption: 'Basic Pack',
                              required: true,
                              prompt: 'Select Basic Pack',
                              searchable: true,
                              remove_search_for_small_list: false },
        standard_pack_code_id: { renderer: :select,
                                 options: MasterfilesApp::FruitSizeRepo.new.for_select_standard_pack_codes,
                                 disabled_options: MasterfilesApp::FruitSizeRepo.new.for_select_inactive_standard_pack_codes,
                                 caption: 'Standard Pack',
                                 required: true,
                                 prompt: 'Select Standard Pack',
                                 searchable: true,
                                 remove_search_for_small_list: false,
                                 hide_on_load: @rules[:hide_some_fields] ? true : false },
        fruit_actual_counts_for_pack_id: { renderer: :select,
                                           options: MasterfilesApp::FruitSizeRepo.new.for_select_fruit_actual_counts_for_packs,
                                           disabled_options: MasterfilesApp::FruitSizeRepo.new.for_select_inactive_fruit_actual_counts_for_packs,
                                           caption: 'Actual Count',
                                           prompt: 'Select Actual Count',
                                           searchable: true,
                                           remove_search_for_small_list: false },
        fruit_size_reference_id: { renderer: :select,
                                   options: MasterfilesApp::FruitSizeRepo.new.for_select_fruit_size_references,
                                   disabled_options: MasterfilesApp::FruitSizeRepo.new.for_select_inactive_fruit_size_references,
                                   caption: 'Size Reference',
                                   prompt: 'Select Size Reference',
                                   searchable: true,
                                   remove_search_for_small_list: false },
        grade_id: { renderer: :select,
                    options: MasterfilesApp::FruitRepo.new.for_select_grades,
                    disabled_options: MasterfilesApp::FruitRepo.new.for_select_inactive_grades,
                    caption: 'Grade',
                    required: true,
                    prompt: 'Select Grade',
                    searchable: true,
                    remove_search_for_small_list: false },
        marketing_org_party_role_id: { renderer: :select,
                                       options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_MARKETER),
                                       selected: default_mkting_org_id,
                                       caption: 'Marketing Org.',
                                       required: true,
                                       prompt: 'Select Marketing Org.',
                                       searchable: true,
                                       remove_search_for_small_list: false },
        packed_tm_group_id: { renderer: :select,
                              options: MasterfilesApp::TargetMarketRepo.new.for_select_target_market_groups(AppConst::PACKED_TM_GROUP),
                              disabled_options: MasterfilesApp::TargetMarketRepo.new.for_select_inactive_tm_groups,
                              caption: 'Packed TM Group',
                              required: true,
                              prompt: 'Select Packed TM Group',
                              searchable: true,
                              remove_search_for_small_list: false },
        sell_by_code: {},
        mark_id: { renderer: :select,
                   options: MasterfilesApp::MarketingRepo.new.for_select_marks,
                   disabled_options: MasterfilesApp::MarketingRepo.new.for_select_inactive_marks,
                   caption: 'Mark',
                   required: true,
                   prompt: 'Select Mark',
                   searchable: true,
                   remove_search_for_small_list: false },
        product_chars: {},
        inventory_code_id: { renderer: :select,
                             options: MasterfilesApp::FruitRepo.new.for_select_inventory_codes,
                             disabled_options: MasterfilesApp::FruitRepo.new.for_select_inactive_inventory_codes,
                             caption: 'Inventory Code',
                             prompt: 'Select Inventory Code',
                             searchable: true,
                             remove_search_for_small_list: false,
                             required: true },
        customer_variety_id: { renderer: :select,
                               options: customer_varieties,
                               disabled_options: MasterfilesApp::MarketingRepo.new.for_select_inactive_customer_varieties,
                               caption: 'Customer Variety',
                               prompt: 'Select Customer Variety',
                               searchable: true,
                               remove_search_for_small_list: false },
        client_product_code: {},
        client_size_reference: {},
        marketing_order_number: {},
        pallet_base_id: { renderer: :select, options: MasterfilesApp::PackagingRepo.new.for_select_pallet_bases,
                          disabled_options: MasterfilesApp::PackagingRepo.new.for_select_inactive_pallet_bases,
                          caption: 'Pallet Base',
                          required: true,
                          prompt: 'Select Pallet Base',
                          searchable: true,
                          remove_search_for_small_list: false },
        pallet_stack_type_id: { renderer: :select, options: MasterfilesApp::PackagingRepo.new.for_select_pallet_stack_types,
                                disabled_options: MasterfilesApp::PackagingRepo.new.for_select_inactive_pallet_stack_types,
                                caption: 'Pallet Stack Type',
                                required: true,
                                prompt: 'Select Pallet Stack Type',
                                searchable: true,
                                remove_search_for_small_list: false },
        pallet_format_id: { renderer: :select, options: MasterfilesApp::PackagingRepo.new.for_select_pallet_formats,
                            disabled_options: MasterfilesApp::PackagingRepo.new.for_select_inactive_pallet_formats,
                            caption: 'Pallet Format',
                            required: true,
                            prompt: 'Select Pallet Format',
                            searchable: true,
                            remove_search_for_small_list: false },
        pallet_label_name: { renderer: :select,
                             options: MasterfilesApp::LabelTemplateRepo.new.for_select_label_templates(where: { application: AppConst::PRINT_APP_PALLET }),
                             caption: 'Pallet Label Name',
                             prompt: 'Select Pallet Label Name',
                             searchable: true,
                             remove_search_for_small_list: false },
        cartons_per_pallet_id: { renderer: :select,
                                 options: MasterfilesApp::PackagingRepo.new.for_select_cartons_per_pallet,
                                 disabled_options: MasterfilesApp::PackagingRepo.new.for_select_inactive_cartons_per_pallet,
                                 caption: 'Cartons per Pallet',
                                 required: true,
                                 prompt: 'Select Cartons per Pallet',
                                 searchable: true,
                                 remove_search_for_small_list: false },
        pm_type_id: { renderer: :select,
                      options: MasterfilesApp::BomsRepo.new.for_select_pm_types,
                      disabled_options: MasterfilesApp::BomsRepo.new.for_select_inactive_pm_types,
                      selected: default_pm_type_id,
                      caption: 'PM Type',
                      prompt: 'Select PM Type',
                      searchable: true,
                      remove_search_for_small_list: false,
                      hide_on_load: @rules[:require_packaging_bom] ? false : true },
        pm_subtype_id: { renderer: :select,
                         options: MasterfilesApp::BomsRepo.new.for_select_pm_subtypes(where: { pm_type_id: default_pm_type_id }),
                         disabled_options: MasterfilesApp::BomsRepo.new.for_select_inactive_pm_subtypes,
                         caption: 'PM Subtype',
                         prompt: 'Select PM Subtype',
                         searchable: true,
                         remove_search_for_small_list: false,
                         hide_on_load: @rules[:require_packaging_bom] ? false : true },
        pm_bom_id: { renderer: :select,
                     options: pm_boms,
                     disabled_options: MasterfilesApp::BomsRepo.new.for_select_inactive_pm_boms,
                     caption: 'PM BOM',
                     prompt: 'Select PM BOM',
                     searchable: true,
                     remove_search_for_small_list: false,
                     hide_on_load: @rules[:require_packaging_bom] ? false : true },
        description: { readonly: true,
                       hide_on_load: @rules[:require_packaging_bom] ? false : true },
        erp_bom_code: { readonly: true,
                        hide_on_load: @rules[:require_packaging_bom] ? false : true },
        active: { renderer: :checkbox },
        # extended_columns: {},
        treatment_ids: { renderer: :multi,
                         options: MasterfilesApp::FruitRepo.new.for_select_treatments,
                         selected: @form_object.treatment_ids,
                         caption: 'Treatments',
                         hide_on_load: @rules[:hide_some_fields] ? true : false }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_product_setup(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(product_setup_template_id: @options[:product_setup_template_id],
                                    marketing_variety_id: nil,
                                    customer_variety_id: nil,
                                    std_fruit_size_count_id: nil,
                                    basic_pack_code_id: nil,
                                    standard_pack_code_id: nil,
                                    fruit_actual_counts_for_pack_id: nil,
                                    fruit_size_reference_id: nil,
                                    marketing_org_party_role_id: nil,
                                    packed_tm_group_id: nil,
                                    mark_id: nil,
                                    inventory_code_id: nil,
                                    pallet_format_id: nil,
                                    cartons_per_pallet_id: nil,
                                    pm_bom_id: nil,
                                    extended_columns: nil,
                                    client_size_reference: nil,
                                    client_product_code: nil,
                                    treatment_ids: nil,
                                    marketing_order_number: nil,
                                    sell_by_code: nil,
                                    pallet_label_name: nil,
                                    grade_id: nil,
                                    product_chars: nil)
    end

    def treatment_codes
      @repo.find_treatment_codes(@options[:id])
    end

    private

    def add_behaviours
      behaviours do |behaviour| # rubocop:disable Metrics/BlockLength
        behaviour.dropdown_change :commodity_id,
                                  notify: [{ url: '/production/product_setups/product_setups/commodity_changed',
                                             param_keys: %i[product_setup_product_setup_template_id] }]
        behaviour.dropdown_change :basic_pack_code_id,
                                  notify: [{ url: '/production/product_setups/product_setups/basic_pack_code_changed',
                                             param_keys: %i[product_setup_std_fruit_size_count_id] }]
        behaviour.dropdown_change :fruit_actual_counts_for_pack_id,
                                  notify: [{ url: '/production/product_setups/product_setups/actual_count_changed' }]
        behaviour.dropdown_change :marketing_variety_id,
                                  notify: [{ url: '/production/product_setups/product_setups/marketing_variety_changed',
                                             param_keys: %i[product_setup_packed_tm_group_id] }]
        behaviour.dropdown_change :packed_tm_group_id,
                                  notify: [{ url: '/production/product_setups/product_setups/packed_tm_group_changed',
                                             param_keys: %i[product_setup_marketing_variety_id] }]
        behaviour.dropdown_change :pallet_stack_type_id,
                                  notify: [{ url: '/production/product_setups/product_setups/pallet_stack_type_changed',
                                             param_keys: %i[product_setup_pallet_base_id] }]
        behaviour.dropdown_change :pallet_format_id,
                                  notify: [{ url: '/production/product_setups/product_setups/pallet_format_changed',
                                             param_keys: %i[product_setup_basic_pack_code_id] }]
        behaviour.dropdown_change :pm_type_id,
                                  notify: [{ url: '/production/product_setups/product_setups/pm_type_changed' }]
        behaviour.dropdown_change :pm_subtype_id,
                                  notify: [{ url: '/production/product_setups/product_setups/pm_subtype_changed' }]
        behaviour.dropdown_change :pm_bom_id,
                                  notify: [{ url: '/production/product_setups/product_setups/pm_bom_changed' }]
      end
    end
  end
end
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity
