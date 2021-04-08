# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'packing_specifications', 'production' do |r|
    # PACKING SPECIFICATION ITEMS
    # --------------------------------------------------------------------------
    r.on 'packing_specification_items', Integer do |id|
      interactor = ProductionApp::PackingSpecificationItemInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:packing_specification_items, id) do
        handle_not_found(r)
      end

      r.on 'activate' do
        check_auth!('packing specifications', 'edit')
        interactor.assert_permission!(:activate, id)
        res = interactor.activate_packing_specification_item(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect request.referer
      end

      r.on 'deactivate' do
        check_auth!('packing specifications', 'edit')
        interactor.assert_permission!(:deactivate, id)
        res = interactor.deactivate_packing_specification_item(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect request.referer
      end

      r.on 'refresh_extended_fg_code' do
        res = interactor.refresh_extended_fg_code(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect request.referer
      end

      r.on 'edit' do   # EDIT
        check_auth!('packing specifications', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Production::PackingSpecifications::PackingSpecificationItem::Edit.call(id) }
      end

      r.on 'clone' do    # NEW
        check_auth!('packing specifications', 'new')
        form_values = interactor.packing_specification_item(id).to_h
        show_partial_or_page(r) do
          Production::PackingSpecifications::PackingSpecificationItem::New.call(remote: fetch?(r), form_values: form_values)
        end
      end

      r.on 'inline_select_pm_marks' do
        specification_item = interactor.packing_specification_item(id)
        items = interactor.for_select_pm_marks(
          where: { mark_id: specification_item.mark_id }
        )
        { items: items }.to_json
      end

      r.on 'inline_select_pm_boms' do
        specification_item = interactor.packing_specification_item(id)
        items = interactor.for_select_packing_spec_pm_boms(
          where: { std_fruit_size_count_id: specification_item.std_fruit_size_count_id,
                   basic_pack_id: specification_item.basic_pack_id }
        )
        { items: items }.to_json
      end

      r.on 'inline_edit' do
        res = interactor.inline_update_packing_specification_item(id, params)
        if res.success
          row_keys = %i[
            description
            pm_bom_id
            pm_bom
            pm_mark_id
            pm_mark
            product_setup_id
            product_setup
            tu_labour_product
            ru_labour_product
            ri_labour_product
            fruit_sticker_1
            fruit_sticker_2
            tu_sticker_1
            tu_sticker_2
            ru_sticker_1
            ru_sticker_2
            status
          ]
          update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
        else
          undo_grid_inline_edit(message: res.message, message_type: :error)
        end
      end

      r.is do
        r.get do       # SHOW
          check_auth!('packing specifications', 'read')
          show_partial_or_page(r) { Production::PackingSpecifications::PackingSpecification::Show.call(id, back_url: back_button_url) }
        end

        r.delete do    # DELETE
          check_auth!('packing specifications', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_packing_specification_item(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'packing_specification_items' do
      interactor = ProductionApp::PackingSpecificationItemInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'product_setup_template_changed' do
        actions = []
        unless params[:changed_value].nil_or_empty?
          product_setup_list = ProductionApp::ProductSetupRepo.new.for_select_product_setups(where: { product_setup_template_id: params[:changed_value] })
          actions << OpenStruct.new(type: :replace_select_options, dom_id: 'packing_specification_item_product_setup_id', options_array: product_setup_list)
        end
        json_actions(actions)
      end

      r.on 'product_setup_changed' do
        actions = []
        unless params[:changed_value].nil_or_empty?
          repo = MasterfilesApp::BomRepo.new
          product_setup = repo.where_hash(:product_setups, id: params[:changed_value])
          pm_bom_list = repo.for_select_pm_boms(where: { std_fruit_size_count_id: product_setup[:std_fruit_size_count_id] })
          pm_mark_list = repo.for_select_pm_marks(where: { mark_id: product_setup[:mark_id] })
          actions << OpenStruct.new(type: :replace_select_options, dom_id: 'packing_specification_item_pm_bom_id', options_array: pm_bom_list)
          actions << OpenStruct.new(type: :replace_select_options, dom_id: 'packing_specification_item_pm_mark_id', options_array: pm_mark_list)
        end
        json_actions(actions)
      end

      r.on 'refresh' do
        res = interactor.refresh_packing_specification_items
        flash[res.success ? :notice : :error] = res.message
        r.redirect '/list/packing_specification_items'
      end
    end

    # PACKING SPECIFICATION WIZARD
    # --------------------------------------------------------------------------
    r.on 'wizard' do
      interactor = ProductionApp::PackingSpecificationItemInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      setup_interactor = ProductionApp::ProductSetupInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      stepper = interactor.stepper(:packing_specification_wizard)

      r.on 'change', String, String, String do |change_rule, change_mode, change_field|
        args = stepper.form_state.merge(params)
        handle_ui_change(change_rule.to_sym, change_mode.to_sym, args, { field: change_field.to_sym })
      end

      r.on 'cancel' do
        referer = stepper.referer
        stepper.cancel

        r.redirect referer
      end

      r.on 'setup' do
        stepper.setup(params.merge(referer: request.referer))
        r.redirect '/production/packing_specifications/wizard'
      end

      r.on 'previous' do
        stepper.previous
        show_partial_or_page(r) do
          stepper.form.call(
            form_values: stepper.form_state
          )
        end
      end

      r.on 'new' do
        res = stepper.current(params[:packing_specification_wizard])
        params = stepper.form_state
        if res.success
          res = setup_interactor.create_product_setup(params)
          if res.success
            params[:product_setup_id] = res.instance.id
            res = interactor.create_packing_specification_item(params) if AppConst::CR_PROD.use_packing_specifications?
            if res.success
              flash[:notice] = res.message
              r.redirect stepper.referer
            end
          end
        end
        re_show_form(r, res, url: '/production/packing_specifications/wizard') do
          stepper.form.call(form_values: params, form_errors: res.errors)
        end
      end

      r.on 'edit' do
        check_auth!('packing specifications', 'edit')
        res = stepper.current(params[:packing_specification_wizard])
        params = stepper.form_state
        if res.success
          res = setup_interactor.update_product_setup(params[:product_setup_id], params)
          if res.success
            params[:product_setup_id] = res.instance.id
            res = interactor.update_packing_specification_item(params[:packing_specification_item_id], params) if AppConst::CR_PROD.use_packing_specifications?
            if res.success
              flash[:notice] = res.message
              r.redirect stepper.referer
            end
          end
        end
        re_show_form(r, res, url: '/production/packing_specifications/wizard') do
          stepper.form.call(form_values: params, form_errors: res.errors)
        end
      end

      r.is do
        r.get do
          check_auth!('packing specifications', 'new')
          stepper.current(params)
          show_partial_or_page(r) do
            stepper.form.call(form_values: stepper.form_state)
          end
        end

        r.post do
          res = stepper.current(params[:packing_specification_wizard])
          if res.success
            stepper.next
            show_partial_or_page(r) do
              stepper.form.call(form_values: stepper.current.instance)
            end
          else
            re_show_form(r, res, url: '/production/packing_specifications/wizard') do
              stepper.form.call(form_values: res.instance, form_errors: res.errors)
            end
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
