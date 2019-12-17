# frozen_string_literal: true

module UiRules
  class ReworksRunSequenceRule < Base # rubocop:disable ClassLength
    def generate_rules  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      @repo = ProductionApp::ReworksRepo.new
      @farm_repo = MasterfilesApp::FarmRepo.new
      @cultivar_repo = MasterfilesApp::CultivarRepo.new

      make_form_object
      apply_form_values

      @rules[:hide_some_fields] = (AppConst::CLIENT_CODE == 'kr')
      @rules[:require_packaging_bom] = AppConst::REQUIRE_PACKAGING_BOM
      @rules[:pm_boms_products] = pm_boms_products(@form_object[:pm_bom_id]) unless @form_object[:pm_bom_id].nil_or_empty?

      if @mode == :change_production_run
        make_reworks_run_pallet_header_table
        set_change_production_run_fields
      end

      if @mode == :edit_farm_details
        make_reworks_run_pallet_header_table(%i[pallet_number pallet_sequence_number], 1)
        set_pallet_sequence_fields
      end

      edit_sequence_fields if @mode == :edit_pallet_sequence

      add_behaviours if %i[change_production_run].include? @mode
      edit_farm_details_behaviours if %i[edit_farm_details].include? @mode
      edit_sequence_behaviours if %i[edit_pallet_sequence].include? @mode

      form_name 'reworks_run_sequence'
    end

    def make_reworks_run_pallet_header_table(columns = nil, display_columns = 3)
      compact_header(columns: columns || %i[pallet_number pallet_sequence_number production_run_id packhouse line farm puc orchard cultivar_group cultivar],
                     display_columns: display_columns)
    end

    def set_change_production_run_fields
      fields[:production_run_id] = { renderer: :select,
                                     options: ProductionApp::ReworksRepo.new.for_select_production_runs(@options[:old_production_run_id]),
                                     caption: 'Production Runs',
                                     prompt: 'Select New Production Run',
                                     searchable: true,
                                     remove_search_for_small_list: false }
      fields[:pallet_sequence_id] = { renderer: :hidden }
      fields[:old_production_run_id] = { renderer: :hidden }
      fields[:reworks_run_type_id] = { renderer: :hidden }
    end

    def set_pallet_sequence_fields  # rubocop:disable Metrics/AbcSize
      cultivar_group_id_label = @cultivar_repo.find_cultivar_group(@form_object.cultivar_group_id)&.cultivar_group_code
      pucs = if @form_object.farm_id.nil_or_empty?
               []
             else
               @farm_repo.selected_farm_pucs(@form_object.farm_id)
             end
      orchards = if @form_object.farm_id.nil_or_empty? || @form_object.puc_id.nil_or_empty?
                   []
                 else
                   @farm_repo.selected_farm_orchard_codes(@form_object.farm_id, @form_object.puc_id)
                 end
      fields[:pallet_sequence_id] = { renderer: :hidden }
      fields[:reworks_run_type_id] = { renderer: :hidden }
      fields[:farm_id] = { renderer: :select,
                           options: @farm_repo.for_select_farms,
                           disabled_options: @farm_repo.for_select_inactive_farms,
                           caption: 'Farm',
                           prompt: true,
                           required: true }
      fields[:puc_id] = { renderer: :select,
                          options: pucs,
                          disabled_options: @farm_repo.for_select_inactive_pucs,
                          caption: 'Puc',
                          required: true }
      fields[:orchard_id] = { renderer: :select,
                              options: orchards,
                              disabled_options: @farm_repo.for_select_inactive_orchards,
                              caption: 'Orchard' }
      fields[:cultivar_group_id] = { renderer: :hidden }
      fields[:cultivar_group] = { renderer: :label,
                                  with_value: cultivar_group_id_label,
                                  caption: 'Cultivar Group' }
      fields[:cultivar_id] = { renderer: :select,
                               options: @cultivar_repo.for_select_cultivars(where: { cultivar_group_id: @form_object.cultivar_group_id }),
                               disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_cultivars,
                               caption: 'Cultivar' }
      fields[:season_id] = { renderer: :select,
                             options: MasterfilesApp::CalendarRepo.new.for_select_seasons_for_cultivar_group(@form_object.cultivar_group_id),
                             disabled_options: MasterfilesApp::CalendarRepo.new.for_select_inactive_seasons,
                             caption: 'Season',
                             required: true }
    end

    def edit_sequence_fields  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity,  Metrics/PerceivedComplexity
      commodity_id_label = MasterfilesApp::CommodityRepo.new.find_commodity(@form_object.commodity_id)&.code
      cultivar_group_id = @form_object[:cultivar_group_id]
      cultivar_id = @form_object[:cultivar_id]
      commodity_id = @form_object[:commodity_id].nil_or_empty? ? ProductionApp::ProductSetupRepo.new.commodity_id(cultivar_group_id, cultivar_id) : @form_object[:commodity_id]
      default_mkting_org_id = @form_object[:marketing_org_party_role_id].nil_or_empty? ? MasterfilesApp::PartyRepo.new.find_party_role_from_party_role_name(AppConst::DEFAULT_MARKETING_ORG) : @form_object[:marketing_org_party_role_id]
      default_pm_type_id = @form_object[:pm_type_id].nil_or_empty? ? MasterfilesApp::BomsRepo.new.find_pm_type(DB[:pm_types].where(pm_type_code: AppConst::DEFAULT_FG_PACKAGING_TYPE).select_map(:id))&.id : @form_object[:pm_type_id]

      pm_boms = if @form_object.pm_subtype_id.nil_or_empty?
                  []
                else
                  MasterfilesApp::BomsRepo.new.for_select_pm_subtype_pm_boms(@form_object.pm_subtype_id)
                end
      fields[:pallet_number] =  { renderer: :label,
                                  with_value: @form_object[:pallet_number],
                                  caption: 'Pallet Number',
                                  readonly: true }
      fields[:pallet_sequence_number] =  { renderer: :label,
                                           with_value: @form_object[:pallet_sequence_number],
                                           caption: 'Pallet Sequence Number',
                                           readonly: true }
      fields[:commodity_id] =  { renderer: :label,
                                 with_value: commodity_id_label,
                                 caption: 'Commodity' }
      fields[:marketing_variety_id] =  { renderer: :select,
                                         options: @repo.for_select_template_commodity_marketing_varieties(commodity_id),
                                         disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_marketing_varieties,
                                         caption: 'Marketing Variety',
                                         required: true,
                                         prompt: 'Select Marketing Variety',
                                         searchable: true,
                                         remove_search_for_small_list: false }
      fields[:std_fruit_size_count_id] =  { renderer: :select,
                                            options: MasterfilesApp::FruitSizeRepo.new.for_select_std_fruit_size_counts,
                                            disabled_options: MasterfilesApp::FruitSizeRepo.new.for_select_inactive_std_fruit_size_counts,
                                            caption: 'Std Size Count',
                                            prompt: 'Select Size Count',
                                            searchable: true,
                                            remove_search_for_small_list: false }
      fields[:basic_pack_code_id] =  { renderer: :select,
                                       options: MasterfilesApp::FruitSizeRepo.new.for_select_basic_pack_codes,
                                       disabled_options: MasterfilesApp::FruitSizeRepo.new.for_select_inactive_basic_pack_codes,
                                       caption: 'Basic Pack',
                                       required: true,
                                       prompt: 'Select Basic Pack',
                                       searchable: true,
                                       remove_search_for_small_list: false }
      fields[:standard_pack_code_id] =  { renderer: :select,
                                          options: MasterfilesApp::FruitSizeRepo.new.for_select_standard_pack_codes,
                                          disabled_options: MasterfilesApp::FruitSizeRepo.new.for_select_inactive_standard_pack_codes,
                                          caption: 'Standard Pack',
                                          required: true,
                                          prompt: 'Select Standard Pack',
                                          searchable: true,
                                          remove_search_for_small_list: false,
                                          hide_on_load: @rules[:hide_some_fields] ? true : false }
      fields[:fruit_actual_counts_for_pack_id] =  { renderer: :select,
                                                    options: MasterfilesApp::FruitSizeRepo.new.for_select_fruit_actual_counts_for_packs,
                                                    disabled_options: MasterfilesApp::FruitSizeRepo.new.for_select_inactive_fruit_actual_counts_for_packs,
                                                    caption: 'Actual Count',
                                                    prompt: 'Select Actual Count',
                                                    searchable: true,
                                                    remove_search_for_small_list: false }
      fields[:fruit_size_reference_id] =  { renderer: :select,
                                            options: MasterfilesApp::FruitSizeRepo.new.for_select_fruit_size_references,
                                            disabled_options: MasterfilesApp::FruitSizeRepo.new.for_select_inactive_fruit_size_references,
                                            caption: 'Size Reference',
                                            prompt: 'Select Size Reference',
                                            searchable: true,
                                            remove_search_for_small_list: false }
      fields[:grade_id] =  { renderer: :select,
                             options: MasterfilesApp::FruitRepo.new.for_select_grades,
                             disabled_options: MasterfilesApp::FruitRepo.new.for_select_inactive_grades,
                             caption: 'Grade',
                             required: true,
                             prompt: 'Select Grade',
                             searchable: true,
                             remove_search_for_small_list: false }
      fields[:marketing_org_party_role_id] =  { renderer: :select,
                                                options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_MARKETER),
                                                selected: default_mkting_org_id,
                                                caption: 'Marketing Org.',
                                                required: true,
                                                prompt: 'Select Marketing Org.',
                                                searchable: true,
                                                remove_search_for_small_list: false }
      fields[:packed_tm_group_id] =  { renderer: :select,
                                       options: MasterfilesApp::TargetMarketRepo.new.for_select_target_market_groups(AppConst::PACKED_TM_GROUP),
                                       disabled_options: MasterfilesApp::TargetMarketRepo.new.for_select_inactive_tm_groups,
                                       caption: 'Packed TM Group',
                                       required: true,
                                       prompt: 'Select Packed TM Group',
                                       searchable: true,
                                       remove_search_for_small_list: false }
      fields[:sell_by_code] =  {}
      fields[:mark_id] =  { renderer: :select,
                            options: MasterfilesApp::MarketingRepo.new.for_select_marks,
                            disabled_options: MasterfilesApp::MarketingRepo.new.for_select_inactive_marks,
                            caption: 'Mark',
                            required: true,
                            prompt: 'Select Mark',
                            searchable: true,
                            remove_search_for_small_list: false }
      fields[:product_chars] =  {}
      fields[:inventory_code_id] =  { renderer: :select,
                                      options: MasterfilesApp::FruitRepo.new.for_select_inventory_codes,
                                      disabled_options: MasterfilesApp::FruitRepo.new.for_select_inactive_inventory_codes,
                                      caption: 'Inventory Code',
                                      prompt: 'Select Inventory Code',
                                      searchable: true,
                                      remove_search_for_small_list: false,
                                      required: true }
      fields[:customer_variety_variety_id] =  { renderer: :select,
                                                options: MasterfilesApp::MarketingRepo.new.for_select_customer_variety_varieties,
                                                disabled_options: MasterfilesApp::MarketingRepo.new.for_select_inactive_customer_variety_varieties,
                                                caption: 'Customer Variety Variety',
                                                prompt: 'Select Customer Variety Variety',
                                                searchable: true,
                                                remove_search_for_small_list: false }
      fields[:client_product_code] =  {}
      fields[:client_size_reference] =  {}
      fields[:marketing_order_number] =  {}
      fields[:pallet_base_id] =  { renderer: :select, options: MasterfilesApp::PackagingRepo.new.for_select_pallet_bases,
                                   disabled_options: MasterfilesApp::PackagingRepo.new.for_select_inactive_pallet_bases,
                                   caption: 'Pallet Base',
                                   required: true,
                                   prompt: 'Select Pallet Base',
                                   searchable: true,
                                   remove_search_for_small_list: false }
      fields[:pallet_stack_type_id] =  { renderer: :select, options: MasterfilesApp::PackagingRepo.new.for_select_pallet_stack_types,
                                         disabled_options: MasterfilesApp::PackagingRepo.new.for_select_inactive_pallet_stack_types,
                                         caption: 'Pallet Stack Type',
                                         required: true,
                                         prompt: 'Select Pallet Stack Type',
                                         searchable: true,
                                         remove_search_for_small_list: false }
      fields[:pallet_format_id] =  { renderer: :select, options: MasterfilesApp::PackagingRepo.new.for_select_pallet_formats,
                                     disabled_options: MasterfilesApp::PackagingRepo.new.for_select_inactive_pallet_formats,
                                     caption: 'Pallet Format',
                                     required: true,
                                     prompt: 'Select Pallet Format',
                                     searchable: true,
                                     remove_search_for_small_list: false }
      fields[:pallet_label_name] =  { renderer: :select,
                                      options: MasterfilesApp::LabelTemplateRepo.new.for_select_label_templates(where: { application: AppConst::PRINT_APP_PALLET }),
                                      caption: 'Pallet Label Name',
                                      prompt: 'Select Pallet Label Name',
                                      searchable: true,
                                      remove_search_for_small_list: false }
      fields[:cartons_per_pallet_id] =  { renderer: :select,
                                          options: MasterfilesApp::PackagingRepo.new.for_select_cartons_per_pallet,
                                          disabled_options: MasterfilesApp::PackagingRepo.new.for_select_inactive_cartons_per_pallet,
                                          caption: 'Cartons per Pallet',
                                          required: true,
                                          prompt: 'Select Cartons per Pallet',
                                          searchable: true,
                                          remove_search_for_small_list: false }
      fields[:pm_type_id] = { renderer: :select,
                              options: MasterfilesApp::BomsRepo.new.for_select_pm_types,
                              disabled_options: MasterfilesApp::BomsRepo.new.for_select_inactive_pm_types,
                              selected: default_pm_type_id,
                              caption: 'PM Type',
                              prompt: 'Select PM Type',
                              searchable: true,
                              remove_search_for_small_list: false,
                              hide_on_load: @rules[:require_packaging_bom] ? false : true }
      fields[:pm_subtype_id] =  { renderer: :select,
                                  options: MasterfilesApp::BomsRepo.new.for_select_pm_subtypes(where: { pm_type_id: default_pm_type_id }),
                                  disabled_options: MasterfilesApp::BomsRepo.new.for_select_inactive_pm_subtypes,
                                  caption: 'PM Subtype',
                                  prompt: 'Select PM Subtype',
                                  searchable: true,
                                  remove_search_for_small_list: false,
                                  hide_on_load: @rules[:require_packaging_bom] ? false : true }
      fields[:pm_bom_id] =  { renderer: :select,
                              options: pm_boms,
                              disabled_options: MasterfilesApp::BomsRepo.new.for_select_inactive_pm_boms,
                              caption: 'PM BOM',
                              prompt: 'Select PM BOM',
                              searchable: true,
                              remove_search_for_small_list: false,
                              hide_on_load: @rules[:require_packaging_bom] ? false : true }
      fields[:description] =  { readonly: true,
                                hide_on_load: @rules[:require_packaging_bom] ? false : true }
      fields[:erp_bom_code] =  { readonly: true,
                                 hide_on_load: @rules[:require_packaging_bom] ? false : true }
      fields[:active] =  { renderer: :checkbox }
      fields[:treatment_ids] =  { renderer: :multi,
                                  options: MasterfilesApp::FruitRepo.new.for_select_treatments,
                                  selected: @form_object.treatment_ids,
                                  caption: 'Treatments',
                                  hide_on_load: @rules[:hide_some_fields] ? true : false }
    end

    def make_form_object
      if @mode == :edit_farm_details
        make_farm_details_form_object
        return
      end

      if @mode == :edit_pallet_sequence
        @form_object = @repo.find_pallet_sequence_setup_data(@options[:pallet_sequence_id])
        return
      end

      @form_object = OpenStruct.new(reworks_run_sequence_data(@options[:pallet_sequence_id]).to_h.merge(pallet_sequence_id: @options[:pallet_sequence_id],
                                                                                                        reworks_run_type_id: @options[:reworks_run_type_id],
                                                                                                        old_production_run_id: @options[:old_production_run_id]))
    end

    def make_farm_details_form_object
      res = ProductionApp::ReworksRepo.new.where_hash(:pallet_sequences, id: @options[:pallet_sequence_id])
      @form_object = OpenStruct.new(farm_id: res[:farm_id],
                                    puc_id: res[:puc_id],
                                    orchard_id: res[:orchard_id],
                                    cultivar_group_id: res[:cultivar_group_id],
                                    cultivar_id: res[:cultivar_id],
                                    season_id: res[:season_id],
                                    pallet_sequence_id: @options[:pallet_sequence_id],
                                    reworks_run_type_id: @options[:reworks_run_type_id],
                                    pallet_number: res[:pallet_number],
                                    pallet_sequence_number: res[:pallet_sequence_number])
    end

    def reworks_run_sequence_data(id)
      @repo.reworks_run_pallet_seq_data(id)
    end

    def pm_boms_products(pm_bom_id)
      MasterfilesApp::BomsRepo.new.pm_bom_products(pm_bom_id) unless pm_bom_id.nil?
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :production_run_id,
                                  notify: [{ url: "/production/reworks/pallet_sequences/#{@options[:pallet_sequence_id]}/production_run_changed" }]
      end
    end

    def edit_farm_details_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :farm_id,
                                  notify: [{ url: "/production/reworks/pallet_sequences/#{@options[:pallet_sequence_id]}/farm_changed" }]
        behaviour.dropdown_change :puc_id,
                                  notify: [{ url: "/production/reworks/pallet_sequences/#{@options[:pallet_sequence_id]}/puc_changed",
                                             param_keys: %i[reworks_run_sequence_farm_id] }]
        behaviour.dropdown_change :orchard_id,
                                  notify: [{ url: "/production/reworks/pallet_sequences/#{@options[:pallet_sequence_id]}/orchard_changed",
                                             param_keys: %i[reworks_run_sequence_cultivar_group_id] }]
      end
    end

    def edit_sequence_behaviours  # rubocop:disable Metrics/AbcSize
      behaviours do |behaviour|
        behaviour.dropdown_change :basic_pack_code_id,
                                  notify: [{ url: "/production/reworks/pallet_sequences/#{@options[:pallet_sequence_id]}/basic_pack_code_changed",
                                             param_keys: %i[reworks_run_sequence_std_fruit_size_count_id] }]
        behaviour.dropdown_change :fruit_actual_counts_for_pack_id,
                                  notify: [{ url: "/production/reworks/pallet_sequences/#{@options[:pallet_sequence_id]}/actual_count_changed" }]
        behaviour.dropdown_change :packed_tm_group_id,
                                  notify: [{ url: "/production/reworks/pallet_sequences/#{@options[:pallet_sequence_id]}/packed_tm_group_changed",
                                             param_keys: %i[reworks_run_sequence_marketing_variety_id] }]
        behaviour.dropdown_change :pallet_stack_type_id,
                                  notify: [{ url: "/production/reworks/pallet_sequences/#{@options[:pallet_sequence_id]}/pallet_stack_type_changed",
                                             param_keys: %i[reworks_run_sequence_pallet_base_id] }]
        behaviour.dropdown_change :pallet_format_id,
                                  notify: [{ url: "/production/reworks/pallet_sequences/#{@options[:pallet_sequence_id]}/pallet_format_changed",
                                             param_keys: %i[reworks_run_sequence_basic_pack_code_id] }]
        behaviour.dropdown_change :pm_type_id,
                                  notify: [{ url: "/production/reworks/pallet_sequences/#{@options[:pallet_sequence_id]}/pm_type_changed" }]
        behaviour.dropdown_change :pm_subtype_id,
                                  notify: [{ url: "/production/reworks/pallet_sequences/#{@options[:pallet_sequence_id]}/pm_subtype_changed" }]
        behaviour.dropdown_change :pm_bom_id,
                                  notify: [{ url: "/production/reworks/pallet_sequences/#{@options[:pallet_sequence_id]}/pm_bom_changed" }]
      end
    end
  end
end
