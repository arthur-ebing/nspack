# frozen_string_literal: true

class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'product_setups', 'production' do |r| # rubocop:disable Metrics/BlockLength
    # PRODUCT SETUP TEMPLATES
    # --------------------------------------------------------------------------
    r.on 'product_setup_templates', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = ProductionApp::ProductSetupTemplateInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:product_setup_templates, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('product setups', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { Production::ProductSetups::ProductSetupTemplate::Edit.call(id) }
      end

      r.on 'manage' do   # EDIT
        check_auth!('product setups', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { Production::ProductSetups::ProductSetupTemplate::Manage.call(id, back_url: back_button_url) }
      end

      r.on 'activate' do
        check_auth!('product setups', 'edit')
        interactor.assert_permission!(:activate, id)
        interactor.activate_product_setup_template(id)
        redirect_to_last_grid(r)
      end

      r.on 'deactivate' do
        check_auth!('product setups', 'edit')
        interactor.assert_permission!(:deactivate, id)
        interactor.deactivate_product_setup_template(id)
        redirect_to_last_grid(r)
      end

      r.on 'clone_product_setup_template' do
        r.on 'clone' do
          check_auth!('product setups', 'edit')
          interactor.assert_permission!(:edit, id)
          show_partial_or_page(r) { Production::ProductSetups::ProductSetupTemplate::Clone.call(id) }
        end

        r.post do
          check_auth!('product setups', 'edit')
          interactor.assert_permission!(:edit, id)
          res = interactor.clone_product_setup_template(id, params[:product_setup_template])
          redirect_to_last_grid(r)
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res) { Production::ProductSetups::ProductSetupTemplate::Clone.call(id, form_values: params[:product_setup_template], form_errors: res.errors) }
          end
        end
      end

      r.on 'product_setups' do
        interactor = ProductionApp::ProductSetupInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

        r.on 'new' do    # NEW
          check_auth!('product setups', 'new')
          show_partial_or_page(r) { Production::ProductSetups::ProductSetup::New.call(id, back_url: back_button_url, remote: fetch?(r)) }
        end
        r.post do        # CREATE
          res = interactor.create_product_setup(params[:product_setup])
          if res.success
            flash[:notice] = res.message
            r.redirect("/production/product_setups/product_setup_templates/#{res.instance.product_setup_template_id}/manage")
          else
            re_show_form(r, res, url: "/production/product_setups/product_setup_templates/#{id}/product_setups/new") do
              Production::ProductSetups::ProductSetup::New.call(id,
                                                                back_url: "/production/product_setups/product_setup_templates/#{id}/manage",
                                                                form_values: params[:product_setup],
                                                                form_errors: res.errors,
                                                                remote: fetch?(r))
            end
          end
        end
      end

      r.is do # rubocop:disable Metrics/BlockLength
        r.get do       # SHOW
          check_auth!('product setups', 'read')
          show_partial_or_page(r) { Production::ProductSetups::ProductSetupTemplate::Show.call(id) }
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
              production_line_code
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
          check_auth!('product setups', 'delete')
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
      interactor = ProductionApp::ProductSetupTemplateInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'cultivar_group_changed' do
        if params[:changed_value].blank?
          cultivars = []
        else
          cultivar_group_id = params[:changed_value]
          template_name = params[:product_setup_template_template_name]
          cannot_edit_cultivar = ProductionApp::ProductSetupRepo.new.invalidates_any_product_setups_marketing_varieties?(template_name, "WHERE cultivars.cultivar_group_id = #{cultivar_group_id}")
          cultivars = interactor.for_select_cultivar_group_cultivars(cultivar_group_id)
        end
        if cannot_edit_cultivar
          old_cultivar_group_id = ProductionApp::ProductSetupRepo.new.find_product_setup_template(params[:product_setup_template_id])&.cultivar_group_id
          json_actions([OpenStruct.new(type: :change_select_value,
                                       dom_id: 'product_setup_template_cultivar_group_id',
                                       value: old_cultivar_group_id)],
                       'Cannot change Cultivar Group. Selection invalidates product setup marketing varieties.',
                       keep_dialog_open: true)
        else
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'product_setup_template_cultivar_id',
                                       options_array: cultivars)])
        end
      end

      r.on 'cultivar_changed' do
        cultivar_group_id = params[:product_setup_template_cultivar_group_id]
        if cultivar_group_id.blank? || params[:changed_value].blank?
          cultivar_id = nil
        else
          cultivar_id = params[:changed_value]
          template_name = params[:product_setup_template_template_name]
          cannot_edit_cultivar = ProductionApp::ProductSetupRepo.new.invalidates_any_product_setups_marketing_varieties?(template_name, "WHERE cultivars.cultivar_group_id = #{cultivar_group_id} AND cultivars.id = #{cultivar_id}")
        end
        if cannot_edit_cultivar
          old_cultivar_id = ProductionApp::ProductSetupRepo.new.find_product_setup_template(params[:product_setup_template_id])&.cultivar_id
          json_actions([OpenStruct.new(type: :change_select_value,
                                       dom_id: 'product_setup_template_cultivar_id',
                                       value: old_cultivar_id)],
                       'Cannot change Cultivar. Selection invalidates product setup marketing varieties.',
                       keep_dialog_open: true)
        else
          json_actions([OpenStruct.new(type: :change_select_value,
                                       dom_id: 'product_setup_template_cultivar_id',
                                       value: cultivar_id)])
        end
      end

      r.on 'packhouse_resource_changed' do
        packhouse_resource_lines = if params[:changed_value].blank?
                                     []
                                   else
                                     interactor.for_select_packhouse_lines(params[:changed_value])
                                   end
        json_replace_select_options('product_setup_template_production_line_id', packhouse_resource_lines)
      end

      r.on 'season_group_changed' do
        seasons = if params[:changed_value].blank?
                    []
                  else
                    interactor.for_select_season_group_seasons(params[:changed_value])
                  end
        json_replace_select_options('product_setup_template_season_id', seasons)
      end

      r.on 'new' do    # NEW
        check_auth!('product setups', 'new')
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
            production_line_code
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
      interactor = ProductionApp::ProductSetupInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:product_setups, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('product setups', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { Production::ProductSetups::ProductSetup::Edit.call(id, back_url: back_button_url) }
      end

      r.on 'edit_active_run_setup' do   # EDIT Active Run Setup
        check_auth!('product setups', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { Production::ProductSetups::ProductSetup::Edit.call(id, back_url: back_button_url) }
      end

      r.on 'clone' do   # CLONE
        check_auth!('product setups', 'edit')
        interactor.assert_permission!(:edit, id)
        res = interactor.clone_product_setup(id)
        flash[:notice] = res.message
        r.redirect(back_button_url)
      end

      r.on 'activate' do
        check_auth!('product setups', 'edit')
        interactor.assert_permission!(:activate, id)
        res = interactor.activate_product_setup(id)
        flash[:notice] = res.message
        r.redirect(back_button_url)
      end

      r.on 'deactivate' do
        check_auth!('product setups', 'edit')
        interactor.assert_permission!(:deactivate, id)
        res = interactor.deactivate_product_setup(id)
        flash[:notice] = res.message
        r.redirect(back_button_url)
      end

      r.is do # rubocop:disable Metrics/BlockLength
        r.get do       # SHOW
          check_auth!('product setups', 'read')
          show_partial_or_page(r) { Production::ProductSetups::ProductSetup::Show.call(id, back_url: back_button_url) }
        end
        r.patch do     # UPDATE
          res = interactor.update_product_setup(id, params[:product_setup])
          if res.success
            flash[:notice] = res.message
            r.redirect("/production/product_setups/product_setup_templates/#{res.instance.product_setup_template_id}/manage")
          else
            re_show_form(r, res, url: "/production/product_setups/product_setups/#{id}/edit") do
              Production::ProductSetups::ProductSetup::Edit.call(id,
                                                                 back_url: "/production/product_setups/product_setup_templates/#{res.instance[:product_setup_template_id]}/manage",
                                                                 form_values: params[:product_setup],
                                                                 form_errors: res.errors)
            end
          end
        end
        r.delete do    # DELETE
          check_auth!('product setups', 'delete')
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

    r.on 'product_setups' do # rubocop:disable Metrics/BlockLength
      interactor = ProductionApp::ProductSetupInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'commodity_changed' do
        commodity_id = params[:changed_value]
        product_setup_template_id = params[:product_setup_product_setup_template_id]
        marketing_varieties = interactor.for_select_template_commodity_marketing_varieties(product_setup_template_id, commodity_id)
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
        std_fruit_size_count_id = params[:product_setup_std_fruit_size_count_id]
        if std_fruit_size_count_id.blank? || params[:changed_value].blank?
          actual_counts = []
        else
          basic_pack_code_id = params[:changed_value]
          actual_counts = interactor.for_select_basic_pack_actual_counts(basic_pack_code_id, std_fruit_size_count_id)
        end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'product_setup_fruit_actual_counts_for_pack_id',
                                     options_array: actual_counts)])
      end

      r.on 'std_fruit_size_count_changed' do
        basic_pack_code_id = params[:product_setup_basic_pack_code_id]
        if basic_pack_code_id.blank? || params[:changed_value].blank?
          actual_counts = []
        else
          std_fruit_size_count_id = params[:changed_value]
          actual_counts = interactor.for_select_basic_pack_actual_counts(basic_pack_code_id, std_fruit_size_count_id)
        end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'product_setup_fruit_actual_counts_for_pack_id',
                                     options_array: actual_counts)])
      end

      r.on 'actual_count_changed' do
        if params[:changed_value].blank?
          standard_pack_codes = []
          size_references = []
        else
          fruit_actual_counts_for_pack_id = params[:changed_value]
          actual_count = MasterfilesApp::FruitSizeRepo.new.find_fruit_actual_counts_for_pack(fruit_actual_counts_for_pack_id)
          standard_pack_codes = interactor.for_select_actual_count_standard_pack_codes(actual_count.standard_pack_code_ids.to_a)
          size_references = interactor.for_select_actual_count_size_references(actual_count.size_reference_ids.to_a)
        end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'product_setup_standard_pack_code_id',
                                     options_array: standard_pack_codes),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'product_setup_fruit_size_reference_id',
                                     options_array: size_references)])
      end

      r.on 'packed_tm_group_changed' do
        if params[:changed_value].blank? || params[:product_setup_marketing_variety_id].blank?
          customer_varieties = []
        else
          packed_tm_group_id = params[:changed_value]
          marketing_variety_id = params[:product_setup_marketing_variety_id]
          customer_varieties = interactor.for_select_customer_varieties(packed_tm_group_id, marketing_variety_id)
        end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'product_setup_customer_variety_id',
                                     options_array: customer_varieties)])
      end

      r.on 'marketing_variety_changed' do
        if params[:changed_value].blank? || params[:product_setup_packed_tm_group_id].blank?
          customer_varieties = []
        else
          marketing_variety_id = params[:changed_value]
          packed_tm_group_id = params[:product_setup_packed_tm_group_id]
          customer_varieties = interactor.for_select_customer_varieties(packed_tm_group_id, marketing_variety_id)
        end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'product_setup_customer_variety_id',
                                     options_array: customer_varieties)])
      end

      r.on 'pallet_stack_type_changed' do
        pallet_base_id = params[:product_setup_pallet_base_id]
        if pallet_base_id.blank? || params[:changed_value].blank?
          pallet_formats = []
        else
          pallet_stack_type_id = params[:changed_value]
          pallet_formats = interactor.for_select_pallet_formats(pallet_base_id, pallet_stack_type_id)
        end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'product_setup_pallet_format_id',
                                     options_array: pallet_formats)])
      end

      r.on 'pallet_format_changed' do
        basic_pack_code_id = params[:product_setup_basic_pack_code_id]
        if basic_pack_code_id.blank? || params[:changed_value].blank?
          cartons_per_pallets = []
        else
          pallet_format_id = params[:changed_value]
          cartons_per_pallets = interactor.for_select_cartons_per_pallets(pallet_format_id, basic_pack_code_id)
        end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'product_setup_cartons_per_pallet_id',
                                     options_array: cartons_per_pallets)])
      end

      r.on 'pm_type_changed' do
        pm_subtypes = if params[:changed_value].blank?
                        []
                      else
                        interactor.for_select_pm_type_pm_subtypes(params[:changed_value])
                      end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'product_setup_pm_subtype_id',
                                     options_array: pm_subtypes),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'product_setup_pm_bom_id',
                                     options_array: []),
                      OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'product_setup_description',
                                     value: ''),
                      OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'product_setup_erp_bom_code',
                                     value: ''),
                      OpenStruct.new(type: :replace_inner_html,
                                     dom_id: 'product_setup_pm_boms_products',
                                     value: [])])
      end

      r.on 'pm_subtype_changed' do
        pm_boms = if params[:changed_value].blank?
                    []
                  else
                    interactor.for_select_pm_subtype_pm_boms(params[:changed_value])
                  end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'product_setup_pm_bom_id',
                                     options_array: pm_boms),
                      OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'product_setup_description',
                                     value: ''),
                      OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'product_setup_erp_bom_code',
                                     value: ''),
                      OpenStruct.new(type: :replace_inner_html,
                                     dom_id: 'product_setup_pm_boms_products',
                                     value: [])])
      end

      r.on 'pm_bom_changed' do
        if params[:changed_value].blank?
          pm_bom_description = nil
          pm_bom_erp_bom_code = nil
          pm_bom_products = []
        else
          pm_bom_id = params[:changed_value]
          pm_bom = MasterfilesApp::BomsRepo.new.find_pm_bom(pm_bom_id)
          pm_bom_description = pm_bom&.description
          pm_bom_erp_bom_code = pm_bom&.erp_bom_code
          pm_bom_products = interactor.pm_bom_products_table(pm_bom_id)
        end
        json_actions([OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'product_setup_description',
                                     value: pm_bom_description),
                      OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'product_setup_erp_bom_code',
                                     value: pm_bom_erp_bom_code),
                      OpenStruct.new(type: :replace_inner_html,
                                     dom_id: 'product_setup_pm_boms_products',
                                     value: pm_bom_products)])
      end
    end
  end
end
