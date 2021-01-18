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
              packing_specification_code
              description
              pm_bom_id
              pm_bom
              pm_mark_id
              pm_mark
              product_setup_id
              product_setup
              tu_labour_product_id
              tu_labour_product
              ru_labour_product_id
              ru_labour_product
              ri_labour_product_id
              ri_labour_product
              fruit_sticker_ids
              fruit_stickers
              tu_sticker_ids
              tu_stickers
              ru_sticker_ids
              ru_stickers
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
            packing_specification_code
            description
            pm_bom_id
            pm_bom
            pm_mark_id
            pm_mark
            product_setup_id
            product_setup
            tu_labour_product_id
            tu_labour_product
            ru_labour_product_id
            ru_labour_product
            ri_labour_product_id
            ri_labour_product
            fruit_sticker_ids
            fruit_stickers
            tu_sticker_ids
            tu_stickers
            ru_sticker_ids
            ru_stickers
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
