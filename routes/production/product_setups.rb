# frozen_string_literal: true

class Nspack < Roda # rubocop:disable ClassLength
  route 'product_setups', 'production' do |r| # rubocop:disable Metrics/BlockLength
    # PRODUCT SETUP TEMPLATES
    # --------------------------------------------------------------------------
    r.on 'product_setup_templates', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = ProductionApp::ProductSetupTemplateInteractor.new(current_user, {}, { route_url: request.path }, {})

      # Check for notfound:
      r.on !interactor.exists?(:product_setup_templates, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('product_setups', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Production::ProductSetups::ProductSetupTemplate::Edit.call(id) }
      end

      r.on 'product_setups' do # rubocop:disable Metrics/BlockLength
        interactor = ProductionApp::ProductSetupInteractor.new(current_user, {}, { route_url: request.path }, {})
        r.on 'commodity_changed' do
          commodity_id = params[:changed_value]
          marketing_varieties = interactor.for_select_template_commodity_marketing_varieties(id, commodity_id)
          size_counts = interactor.for_select_template_commodity_size_counts(commodity_id)
          requires_standard_counts = MasterfilesApp::CommodityRepo.new.find_commodity(commodity_id).requires_standard_counts
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'product_setup_marketing_variety_id',
                                       options_array: marketing_varieties),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'product_setup_std_fruit_size_count_id',
                                       options_array: size_counts),
                        OpenStruct.new(type: requires_standard_counts ? :show_element : :hide_element,
                                       dom_id: 'product_setup_std_fruit_size_count_id_field_wrapper'),
                        OpenStruct.new(type: requires_standard_counts ? :show_element : :hide_element,
                                       dom_id: 'product_setup_fruit_actual_counts_for_pack_id_field_wrapper')])
        end

        r.on 'basic_pack_code_changed' do
          basic_pack_code_id = params[:changed_value]
          std_fruit_size_count_id = params[:product_setup_std_fruit_size_count_id]
          actual_counts = interactor.for_select_basic_pack_actual_counts(basic_pack_code_id, std_fruit_size_count_id)
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'product_setup_fruit_actual_counts_for_pack_id',
                                       options_array: actual_counts)])
        end

        r.on 'actual_count_changed' do
          fruit_actual_counts_for_pack_id = params[:changed_value]
          # fruit_actual_counts_for_pack_id = params[:product_setup_fruit_actual_counts_for_pack_id]
          actual_count = MasterfilesApp::FruitSizeRepo.new.find_fruit_actual_counts_for_pack(fruit_actual_counts_for_pack_id)
          standard_pack_codes = interactor.for_select_actual_count_standard_pack_codes(actual_count.standard_pack_code_ids)
          size_references = interactor.for_select_actual_count_size_references(actual_count.size_reference_ids)
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'product_setup_standard_pack_code_id',
                                       options_array: standard_pack_codes),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'product_setup_fruit_size_reference_id',
                                       options_array: size_references)])
        end

        r.on 'packed_tm_group_changed' do
          packed_tm_group_id = params[:changed_value]
          marketing_variety_id = params[:product_setup_marketing_variety_id]
          customer_variety_varieties = interactor.for_select_customer_variety_varieties(packed_tm_group_id, marketing_variety_id)
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'product_setup_customer_variety_variety_id',
                                       options_array: customer_variety_varieties)])
        end

        r.on 'pallet_stack_type_changed' do
          pallet_base_id = params[:product_setup_pallet_base_id]
          pallet_stack_type_id = params[:changed_value]
          pallet_formats = interactor.for_select_pallet_formats(pallet_base_id, pallet_stack_type_id)
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'product_setup_pallet_format_id',
                                       options_array: pallet_formats)])
        end

        r.on 'pallet_format_changed' do
          pallet_format_id = params[:product_setup_pallet_format_id]
          basic_pack_code_id = params[:product_setup_basic_pack_code_id]
          cartons_per_pallets = interactor.for_select_cartons_per_pallets(pallet_format_id, basic_pack_code_id)
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'product_setup_cartons_per_pallet_id',
                                       options_array: cartons_per_pallets)])
        end

        r.on 'pm_type_changed' do
          pm_subtypes = interactor.for_select_pm_type_pm_subtypes(params[:changed_value])
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'product_setup_pm_subtype_id',
                                       options_array: pm_subtypes)])
        end

        r.on 'pm_subtype_changed' do
          pm_subtype_id = params[:product_setup_pm_subtype_id]
          pm_boms = interactor.for_select_pm_subtype_pm_boms(pm_subtype_id)
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'product_setup_pm_bom_id',
                                       options_array: pm_boms)])
        end

        r.on 'pm_bom_changed' do
          pm_bom_id = params[:product_setup_pm_bom_id]
          pm_bom = MasterfilesApp::BomsRepo.new.find_pm_bom(pm_bom_id)
          pm_bom_products = interactor.pm_bom_products(pm_bom_id)
          json_actions([OpenStruct.new(type: :replace_input_value,
                                       dom_id: 'product_setup_description',
                                       value: pm_bom.description),
                        OpenStruct.new(type: :replace_input_value,
                                       dom_id: 'product_setup_erp_bom_code',
                                       value: pm_bom.erp_bom_code),
                        OpenStruct.new(type: :replace_list_items,
                                       dom_id: 'product_setup_pm_boms_products',
                                       items: pm_bom_products)])
        end

        r.on 'treatment_type_changed' do
          treatments = interactor.for_select_treatment_type_treatments(params[:changed_value])
          json_actions([OpenStruct.new(type: :replace_multi_options,
                                       dom_id: 'product_setup_treatment_ids',
                                       options_array: treatments)])
        end

        r.on 'new' do    # NEW
          check_auth!('product_setups', 'new')
          show_partial_or_page(r) { Production::ProductSetups::ProductSetup::New.call(id, remote: fetch?(r)) }
        end
        r.post do        # CREATE
          res = interactor.create_product_setup(params[:product_setup])
          if res.success
            row_keys = %i[
              id
              product_setup_code
              active
              in_production
            ]
            add_grid_row(attrs: select_attributes(res.instance, row_keys),
                         notice: res.message)
          else
            re_show_form(r, res, url: "/production/product_setups/product_setup_templates#{id}/product_setups/new") do
              Production::ProductSetups::ProductSetup::New.call(id,
                                                                form_values: params[:product_setup],
                                                                form_errors: res.errors,
                                                                remote: fetch?(r))
            end
          end
        end
      end

      r.is do # rubocop:disable Metrics/BlockLength
        r.get do       # SHOW
          check_auth!('product_setups', 'read')
          show_partial { Production::ProductSetups::ProductSetupTemplate::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_product_setup_template(id, params[:product_setup_template])
          if res.success
            row_keys = %i[
              template_name
              description
              cultivar_group_code
              cultivar_name
              packhouse_resource_code
              production_line_resource_code
              season_group_code
              season_code
              active
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Production::ProductSetups::ProductSetupTemplate::Edit.call(id, form_values: params[:product_setup_template], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('product_setups', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_product_setup_template(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'product_setup_templates' do # rubocop:disable Metrics/BlockLength
      interactor = ProductionApp::ProductSetupTemplateInteractor.new(current_user, {}, { route_url: request.path }, {})

      r.on 'cultivar_group_changed' do
        cultivars = interactor.for_select_cultivar_group_cultivars(params[:changed_value])
        json_replace_select_options('product_setup_template_cultivar_id', cultivars)
      end

      r.on 'packhouse_resource_changed' do
        packhouse_resource_lines = interactor.for_select_packhouse_lines(params[:changed_value])
        json_replace_select_options('product_setup_template_production_line_resource_id', packhouse_resource_lines)
      end

      r.on 'season_group_changed' do
        seasons = interactor.for_select_season_group_seasons(params[:changed_value])
        json_replace_select_options('product_setup_template_season_id', seasons)
      end

      r.on 'new' do    # NEW
        check_auth!('product_setups', 'new')
        show_partial_or_page(r) { Production::ProductSetups::ProductSetupTemplate::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_product_setup_template(params[:product_setup_template])
        if res.success
          row_keys = %i[
            id
            template_name
            description
            cultivar_group_code
            cultivar_name
            packhouse_resource_code
            production_line_resource_code
            season_group_code
            season_code
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/production/product_setups/product_setup_templates/new') do
            Production::ProductSetups::ProductSetupTemplate::New.call(form_values: params[:product_setup_template],
                                                                      form_errors: res.errors,
                                                                      remote: fetch?(r))
          end
        end
      end
    end

    # PRODUCT SETUPS
    # --------------------------------------------------------------------------
    r.on 'product_setups', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = ProductionApp::ProductSetupInteractor.new(current_user, {}, { route_url: request.path }, {})

      # Check for notfound:
      r.on !interactor.exists?(:product_setups, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('product_setups', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Production::ProductSetups::ProductSetup::Edit.call(id) }
      end

      r.is do # rubocop:disable Metrics/BlockLength
        r.get do       # SHOW
          check_auth!('product_setups', 'read')
          show_partial { Production::ProductSetups::ProductSetup::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_product_setup(id, params[:product_setup])
          if res.success
            row_keys = %i[
              product_setup_code
              active
              in_production
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Production::ProductSetups::ProductSetup::Edit.call(id, form_values: params[:product_setup], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('product_setups', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_product_setup(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end
  end
end
