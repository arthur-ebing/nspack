# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'packing_specifications', 'production' do |r|
    # PACKING SPECIFICATIONS
    # --------------------------------------------------------------------------
    r.on 'packing_specifications', Integer do |id|
      interactor = ProductionApp::PackingSpecificationInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:packing_specifications, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('packing specifications', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Production::PackingSpecifications::PackingSpecification::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('packing specifications', 'read')
          show_partial { Production::PackingSpecifications::PackingSpecification::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_packing_specification(id, params[:packing_specification])
          if res.success
            row_keys = %i[
              product_setup_template_id
              product_setup_template
              packing_specification_code
              description
              status
              active
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Production::PackingSpecifications::PackingSpecification::Edit.call(id, form_values: params[:packing_specification], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('packing specifications', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_packing_specification(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'packing_specifications' do
      interactor = ProductionApp::PackingSpecificationInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('packing specifications', 'new')
        show_partial_or_page(r) { Production::PackingSpecifications::PackingSpecification::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_packing_specification(params[:packing_specification])
        if res.success
          flash[:notice] = res.message
          redirect_via_json "/list/packing_specification_items/with_params?key=packing_specification&id=#{res.instance.id}&packing_specification=#{res.instance.packing_specification_code}"
        else
          re_show_form(r, res, url: '/production/packing_specifications/packing_specifications/new') do
            Production::PackingSpecifications::PackingSpecification::New.call(form_values: params[:packing_specification],
                                                                              form_errors: res.errors,
                                                                              remote: fetch?(r))
          end
        end
      end
    end
    # PACKING SPECIFICATION ITEMS
    # --------------------------------------------------------------------------
    r.on 'packing_specification_items', Integer do |id|
      interactor = ProductionApp::PackingSpecificationItemInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:packing_specification_items, id) do
        handle_not_found(r)
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
        items = interactor.for_select_pm_marks(where: { mark_id: specification_item.mark_id })
        { items: items }.to_json
      end

      r.on 'inline_select_pm_boms' do
        specification_item = interactor.packing_specification_item(id)
        items = interactor.for_select_pm_boms(where: { std_fruit_size_count_id: specification_item.std_fruit_size_count_id })
        { items: items }.to_json
      end

      r.on 'inline_edit' do
        res = interactor.inline_update_packing_specification_item(id, params)
        if res.success
          row_keys = %i[
            packing_specification_id
            packing_specification
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
          show_partial { Production::PackingSpecifications::PackingSpecificationItem::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_packing_specification_item(id, params[:packing_specification_item])
          if res.success
            row_keys = %i[
              packing_specification_id
              packing_specification
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
            re_show_form(r, res) { Production::PackingSpecifications::PackingSpecificationItem::Edit.call(id, form_values: params[:packing_specification_item], form_errors: res.errors) }
          end
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

      r.on 'packing_specification_changed' do
        actions = []
        unless params[:changed_value].nil_or_empty?
          repo = MasterfilesApp::BomRepo.new
          product_setup_template_id = repo.get(:packing_specifications, params[:changed_value], :product_setup_template_id)
          product_setup_list = ProductionApp::ProductSetupRepo.new.for_select_product_setups(where: { product_setup_template_id: product_setup_template_id })
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

      r.on 'new' do    # NEW
        check_auth!('packing specifications', 'new')
        show_partial_or_page(r) { Production::PackingSpecifications::PackingSpecificationItem::New.call(remote: fetch?(r)) }
      end

      r.post do        # CREATE
        res = interactor.create_packing_specification_item(params[:packing_specification_item])
        if res.success
          row_keys = %i[
            id
            packing_specification_id
            packing_specification
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
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/production/packing_specifications/packing_specification_items/new') do
            Production::PackingSpecifications::PackingSpecificationItem::New.call(form_values: params[:packing_specification_item],
                                                                                  form_errors: res.errors,
                                                                                  remote: fetch?(r))
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
