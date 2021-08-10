# frozen_string_literal: true

module UiRules
  class ProductSetupRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules # rubocop:disable Metrics/AbcSize
      @repo = ProductionApp::ProductSetupRepo.new
      @fruit_size_repo = MasterfilesApp::FruitSizeRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      @tm_repo = MasterfilesApp::TargetMarketRepo.new
      @commodity_repo = MasterfilesApp::CommodityRepo.new
      make_form_object
      apply_form_values

      @rules[:gtins_required] = AppConst::CR_PROD.use_gtins?
      @rules[:basic_pack_equals_standard_pack] = AppConst::CR_MF.basic_pack_equals_standard_pack?
      @rules[:color_applies] ||= @repo.get(:commodities, @form_object.commodity_id, :color_applies) || false

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      add_behaviours if %i[new edit].include? @mode

      form_name 'product_setup'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      product_setup_template_id_label = @repo.get(:product_setup_templates, @form_object.product_setup_template_id, :template_name)
      marketing_variety_id_label = @repo.get(:marketing_varieties, @form_object.marketing_variety_id, :marketing_variety_code)
      customer_variety_id_label = MasterfilesApp::MarketingRepo.new.find_customer_variety(@form_object.customer_variety_id)&.variety_as_customer_variety
      std_fruit_size_count_id_label = @fruit_size_repo.find_std_fruit_size_count(@form_object.std_fruit_size_count_id)&.size_count_value
      basic_pack_code_id_label = @repo.get(:basic_pack_codes, @form_object.basic_pack_code_id, :basic_pack_code)
      standard_pack_code_id_label = @repo.get(:standard_pack_codes, @form_object.standard_pack_code_id, :standard_pack_code)
      fruit_actual_counts_for_pack_id_label = @fruit_size_repo.find_fruit_actual_counts_for_pack(@form_object.fruit_actual_counts_for_pack_id)&.actual_count_for_pack
      fruit_size_reference_id_label = @fruit_size_repo.find_fruit_size_reference(@form_object.fruit_size_reference_id)&.size_reference
      marketing_org_party_role_id_label = @party_repo.find_party_role(@form_object.marketing_org_party_role_id)&.party_name
      packed_tm_group_id_label = @repo.get(:target_market_groups, @form_object.packed_tm_group_id, :target_market_group_name)
      target_market_id_label = @repo.get(:target_markets, @form_object.target_market_id, :target_market_name)
      target_customer_label = @party_repo.fn_party_role_name(@form_object.target_customer_party_role_id)
      mark_id_label = @repo.get(:marks, @form_object.mark_id, :mark_code)
      inventory_code_id_label = MasterfilesApp::FruitRepo.new.find_inventory_code(@form_object.inventory_code_id)&.inventory_code
      pallet_format_id_label = @repo.get(:pallet_formats, @form_object.pallet_format_id, :description)
      cartons_per_pallet_id_label = @repo.get(:cartons_per_pallet, @form_object.cartons_per_pallet_id, :cartons_per_pallet)
      commodity_id_label = @commodity_repo.find_commodity(@form_object.commodity_id)&.code
      grade_id_label = MasterfilesApp::FruitRepo.new.find_grade(@form_object.grade_id)&.grade_code
      pallet_base_id_label = MasterfilesApp::PackagingRepo.new.find_pallet_base(@form_object.pallet_base_id)&.pallet_base_code
      pallet_stack_type_id_label = MasterfilesApp::PackagingRepo.new.find_pallet_stack_type(@form_object.pallet_stack_type_id)&.stack_type_code
      product_setup_template = @repo.find_product_setup_template(@form_object.product_setup_template_id)
      cultivar_group_id_label = product_setup_template&.cultivar_group_code
      cultivar_id_label = product_setup_template&.cultivar_name
      rmt_class_id_label = MasterfilesApp::FruitRepo.new.find_rmt_class(@form_object.rmt_class_id)&.rmt_class_code
      color_percentage_id_label = @repo.get(:color_percentages, @form_object.color_percentage_id, :description)

      fields[:product_setup_template_id] = { renderer: :label,
                                             with_value: product_setup_template_id_label,
                                             caption: 'Product Setup Template' }
      fields[:cultivar_group] = { renderer: :label,
                                  with_value: cultivar_group_id_label,
                                  caption: 'Cultivar Group' }
      fields[:cultivar] = { renderer: :label,
                            with_value: cultivar_id_label,
                            caption: 'Cultivar' }
      fields[:marketing_variety_id] = { renderer: :label,
                                        with_value: marketing_variety_id_label,
                                        caption: 'Marketing Variety' }
      fields[:customer_variety_id] = { renderer: :label,
                                       with_value: customer_variety_id_label,
                                       caption: 'Customer Variety' }
      fields[:std_fruit_size_count_id] = { renderer: :label,
                                           with_value: std_fruit_size_count_id_label,
                                           caption: 'Std Fruit Size Count' }
      fields[:basic_pack_code_id] = { renderer: :label,
                                      with_value: basic_pack_code_id_label,
                                      caption: 'Basic Pack' }
      fields[:standard_pack_code_id] = { renderer: :label,
                                         with_value: standard_pack_code_id_label,
                                         caption: 'Standard Pack',
                                         hide_on_load: @rules[:basic_pack_equals_standard_pack] }
      fields[:fruit_actual_counts_for_pack_id] = { renderer: :label,
                                                   with_value: fruit_actual_counts_for_pack_id_label,
                                                   caption: 'Actual Count' }
      fields[:fruit_size_reference_id] = { renderer: :label,
                                           with_value: fruit_size_reference_id_label,
                                           caption: 'Size Reference' }
      fields[:marketing_org_party_role_id] = { renderer: :label,
                                               with_value: marketing_org_party_role_id_label,
                                               caption: 'Marketing Org' }
      fields[:packed_tm_group_id] = { renderer: :label,
                                      with_value: packed_tm_group_id_label,
                                      caption: 'Packed TM Group' }
      fields[:target_market_id] = { renderer: :label,
                                    with_value: target_market_id_label,
                                    caption: 'Target Market' }
      fields[:target_customer_party_role_id] = { renderer: :label,
                                                 with_value: target_customer_label,
                                                 invisible: !AppConst::CR_PROD.link_target_markets_to_target_customers?,
                                                 caption: 'Target Customer' }
      fields[:mark_id] = { renderer: :label,
                           with_value: mark_id_label,
                           caption: 'Mark' }
      fields[:inventory_code_id] = { renderer: :label,
                                     with_value: inventory_code_id_label,
                                     caption: 'Inventory Code' }
      fields[:pallet_format_id] = { renderer: :label,
                                    with_value: pallet_format_id_label,
                                    caption: 'Pallet Format' }
      fields[:cartons_per_pallet_id] = { renderer: :label,
                                         with_value: cartons_per_pallet_id_label,
                                         caption: 'Cartons Per Pallet' }
      fields[:extended_columns] = { renderer: :label }
      fields[:client_size_reference] = { renderer: :label }
      fields[:client_product_code] = { renderer: :label }
      fields[:marketing_order_number] = { renderer: :label }
      fields[:sell_by_code] = { renderer: :label }
      fields[:pallet_label_name] = { renderer: :label }
      fields[:active] = { renderer: :label,
                          as_boolean: true,
                          hide_on_load: true }
      fields[:treatment_ids] = { renderer: :list, items: treatment_codes,
                                 caption: 'Treatments' }
      fields[:commodity_id] = { renderer: :label,
                                with_value: commodity_id_label,
                                caption: 'Commodity' }
      fields[:rmt_class_id] = { renderer: :label,
                                with_value: rmt_class_id_label,
                                caption: 'Class',
                                invisible: !AppConst::CR_PROD.capture_product_setup_class? }
      fields[:grade_id] = { renderer: :label,
                            with_value: grade_id_label,
                            caption: 'Grade' }
      fields[:pallet_base_id] = { renderer: :label,
                                  with_value: pallet_base_id_label,
                                  caption: 'Pallet Base' }
      fields[:pallet_stack_type_id] = { renderer: :label,
                                        with_value: pallet_stack_type_id_label,
                                        caption: 'Pallet Stack Type' }
      fields[:product_chars] = { renderer: :label }
      fields[:gtin_code] = { renderer: :label,
                             caption: 'GTIN Code',
                             hide_on_load: !@rules[:gtins_required] }
      fields[:color_percentage_id] = { renderer: :label,
                                       with_value: color_percentage_id_label,
                                       hide_on_load: !@rules[:color_applies],
                                       caption: 'Color Percentage' }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      product_setup_template_id = @options[:product_setup_template_id].nil_or_empty? ? @repo.find_product_setup(@options[:id]).product_setup_template_id : @options[:product_setup_template_id]
      product_setup_template = @repo.find_product_setup_template(product_setup_template_id)
      product_setup_template_id_label = product_setup_template&.template_name
      cultivar_group_id = product_setup_template&.cultivar_group_id
      cultivar_group_id_label = product_setup_template&.cultivar_group_code
      cultivar_id = product_setup_template&.cultivar_id
      cultivar_id_label = product_setup_template&.cultivar_name
      # commodity_id = @form_object[:commodity_id].nil_or_empty? ? @repo.get_commodity_id(cultivar_group_id, cultivar_id) : @form_object.commodity_id
      commodity_id = @form_object[:commodity_id].nil_or_empty? ? @repo.get(:cultivar_groups, cultivar_group_id, :commodity_id) : @form_object.commodity_id
      color_applies = @repo.get(:commodities, commodity_id, :color_applies)
      default_mkting_org_id = @form_object[:marketing_org_party_role_id].nil_or_empty? ? @party_repo.find_party_role_from_party_name_for_role(AppConst::CR_PROD.default_marketing_org, AppConst::ROLE_MARKETER) : @form_object[:marketing_org_party_role_id]
      {
        product_setup_template: { renderer: :label,
                                  with_value: product_setup_template_id_label,
                                  caption: 'Product Setup Template',
                                  readonly: true },
        product_setup_template_id: { renderer: :hidden,
                                     value: product_setup_template_id },
        cultivar_group: { renderer: :label,
                          with_value: cultivar_group_id_label,
                          caption: 'Cultivar Group',
                          readonly: true },
        cultivar: { renderer: :label,
                    with_value: cultivar_id_label,
                    caption: 'Cultivar',
                    readonly: true },
        commodity_id: { renderer: :select,
                        options: @repo.for_select_template_cultivar_commodities(cultivar_group_id, cultivar_id),
                        disabled_options: @commodity_repo.for_select_inactive_commodities,
                        caption: 'Commodity',
                        required: true,
                        searchable: true,
                        remove_search_for_small_list: false },
        marketing_variety_id: { renderer: :select,
                                options: @repo.for_select_template_commodity_marketing_varieties(product_setup_template_id, commodity_id, cultivar_id),
                                disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_marketing_varieties,
                                caption: 'Marketing Variety',
                                required: true,
                                prompt: 'Select Marketing Variety',
                                searchable: true,
                                remove_search_for_small_list: false },
        std_fruit_size_count_id: { renderer: :select,
                                   options: @fruit_size_repo.for_select_std_fruit_size_counts(
                                     where: { commodity_id: commodity_id }
                                   ),
                                   disabled_options: @fruit_size_repo.for_select_inactive_std_fruit_size_counts,
                                   caption: 'Std Size Count',
                                   prompt: 'Select Size Count',
                                   searchable: true,
                                   remove_search_for_small_list: false },
        basic_pack_code_id: { renderer: :select,
                              options: @fruit_size_repo.for_select_basic_packs,
                              disabled_options: @fruit_size_repo.for_select_inactive_basic_packs,
                              caption: 'Basic Pack',
                              required: true,
                              prompt: 'Select Basic Pack',
                              searchable: true,
                              remove_search_for_small_list: false },
        standard_pack_code_id: { renderer: :select,
                                 options: @fruit_size_repo.for_select_standard_packs,
                                 disabled_options: @fruit_size_repo.for_select_inactive_standard_packs,
                                 caption: 'Standard Pack',
                                 required: !@rules[:basic_pack_equals_standard_pack],
                                 prompt: 'Select Standard Pack',
                                 searchable: true,
                                 hide_on_load: @rules[:basic_pack_equals_standard_pack],
                                 remove_search_for_small_list: false },
        fruit_actual_counts_for_pack_id: { renderer: :select,
                                           options: @fruit_size_repo.for_select_fruit_actual_counts_for_packs(
                                             where: { basic_pack_code_id: @form_object.basic_pack_code_id,
                                                      std_fruit_size_count_id: @form_object.std_fruit_size_count_id }
                                           ),
                                           disabled_options: @fruit_size_repo.for_select_inactive_fruit_actual_counts_for_packs,
                                           caption: 'Actual Count',
                                           prompt: 'Select Actual Count',
                                           searchable: true,
                                           remove_search_for_small_list: false },
        fruit_size_reference_id: { renderer: :select,
                                   options: @fruit_size_repo.for_select_fruit_size_references,
                                   disabled_options: @fruit_size_repo.for_select_inactive_fruit_size_references,
                                   caption: 'Size Reference',
                                   prompt: 'Select Size Reference',
                                   searchable: true,
                                   remove_search_for_small_list: false },
        rmt_class_id: { renderer: :select,
                        options: MasterfilesApp::FruitRepo.new.for_select_rmt_classes,
                        disabled_options: MasterfilesApp::FruitRepo.new.for_select_inactive_rmt_classes,
                        invisible: !AppConst::CR_PROD.capture_product_setup_class?,
                        caption: 'Class',
                        prompt: 'Select Class',
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
                                       options: @party_repo.for_select_party_roles(AppConst::ROLE_MARKETER),
                                       selected: default_mkting_org_id,
                                       caption: 'Marketing Org',
                                       required: true,
                                       prompt: 'Select Marketing Org',
                                       searchable: true,
                                       remove_search_for_small_list: false },
        packed_tm_group_id: { renderer: :select,
                              options: @tm_repo.for_select_packed_tm_groups,
                              disabled_options: @tm_repo.for_select_inactive_tm_groups,
                              caption: 'Packed TM Group',
                              required: true,
                              prompt: 'Select Packed TM Group',
                              searchable: true,
                              remove_search_for_small_list: false },
        target_market_id: { renderer: :select,
                            options: @tm_repo.for_select_packed_group_tms(
                              where: { target_market_group_id: @form_object.packed_tm_group_id }
                            ),
                            disabled_options: @tm_repo.for_select_inactive_target_markets,
                            caption: 'Target Market',
                            prompt: 'Select Target Market',
                            searchable: true,
                            remove_search_for_small_list: false },
        target_customer_party_role_id: { renderer: :select,
                                         options: @party_repo.for_select_party_roles(AppConst::ROLE_TARGET_CUSTOMER),
                                         invisible: !AppConst::CR_PROD.link_target_markets_to_target_customers?,
                                         caption: 'Target Customer',
                                         prompt: 'Select Target Customer',
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
                               options: MasterfilesApp::MarketingRepo.new.for_select_customer_varieties(
                                 where: { packed_tm_group_id: @form_object.packed_tm_group_id,
                                          marketing_variety_id: @form_object.marketing_variety_id }
                               ),
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
                             options: MasterfilesApp::LabelTemplateRepo.new.for_select_label_templates(
                               where: { application: AppConst::PRINT_APP_PALLET }
                             ),
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
        active: { renderer: :checkbox },
        treatment_ids: { renderer: :multi,
                         options: MasterfilesApp::FruitRepo.new.for_select_treatments,
                         selected: @form_object.treatment_ids,
                         caption: 'Treatments' },
        gtin_code: { renderer: :label,
                     caption: 'GTIN Code',
                     hide_on_load: !@rules[:gtins_required] },
        color_percentage_id: { renderer: :select,
                               options: @commodity_repo.for_select_color_percentages(
                                 where: { commodity_id: commodity_id }
                               ),
                               disabled_options: @commodity_repo.for_select_inactive_color_percentages,
                               caption: 'Color Percentage',
                               prompt: 'Select Color Percentage',
                               hide_on_load: !color_applies,
                               searchable: true,
                               remove_search_for_small_list: false }

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
                                    target_market_id: nil,
                                    target_customer_party_role_id: nil,
                                    mark_id: nil,
                                    inventory_code_id: nil,
                                    pallet_format_id: nil,
                                    cartons_per_pallet_id: nil,
                                    extended_columns: nil,
                                    client_size_reference: nil,
                                    client_product_code: nil,
                                    treatment_ids: nil,
                                    marketing_order_number: nil,
                                    sell_by_code: nil,
                                    pallet_label_name: nil,
                                    grade_id: nil,
                                    product_chars: nil,
                                    gtin_code: nil,
                                    rmt_class_id: nil,
                                    color_percentage_id: nil)
    end

    def treatment_codes
      @repo.find_treatment_codes(@options[:id])
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :commodity_id,
                                  notify: [{ url: '/production/product_setups/product_setups/commodity_changed',
                                             param_keys: %i[product_setup_product_setup_template_id] }]
        behaviour.dropdown_change :basic_pack_code_id,
                                  notify: [{ url: '/production/product_setups/product_setups/basic_pack_code_changed',
                                             param_keys: %i[product_setup_commodity_id product_setup_std_fruit_size_count_id] }]
        behaviour.dropdown_change :std_fruit_size_count_id,
                                  notify: [{ url: '/production/product_setups/product_setups/std_fruit_size_count_changed',
                                             param_keys: %i[product_setup_commodity_id product_setup_basic_pack_code_id] }]
        behaviour.dropdown_change :fruit_actual_counts_for_pack_id,
                                  notify: [{ url: '/production/product_setups/product_setups/actual_count_changed' }]
        behaviour.dropdown_change :marketing_variety_id,
                                  notify: [{ url: '/production/product_setups/product_setups/marketing_variety_changed',
                                             param_keys: %i[product_setup_packed_tm_group_id] }]
        behaviour.dropdown_change :packed_tm_group_id,
                                  notify: [{ url: '/production/product_setups/product_setups/packed_tm_group_changed',
                                             param_keys: %i[product_setup_marketing_variety_id] }]
        # behaviour.dropdown_change :target_market_id,
        #                           notify: [{ url: '/production/product_setups/product_setups/target_market_changed' }]
        behaviour.dropdown_change :pallet_stack_type_id,
                                  notify: [{ url: '/production/product_setups/product_setups/pallet_stack_type_changed',
                                             param_keys: %i[product_setup_pallet_base_id] }]
        behaviour.dropdown_change :pallet_format_id,
                                  notify: [{ url: '/production/product_setups/product_setups/pallet_format_changed',
                                             param_keys: %i[product_setup_basic_pack_code_id] }]
      end
    end
  end
end
