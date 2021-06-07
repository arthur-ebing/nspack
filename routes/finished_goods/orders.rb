# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength, Metrics/ClassLength
class Nspack < Roda
  route 'orders', 'finished_goods' do |r|
    # ORDERS
    # --------------------------------------------------------------------------
    r.on 'orders', Integer do |id|
      interactor = FinishedGoodsApp::OrderInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:orders, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('orders', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { FinishedGoods::Orders::Order::Edit.call(id) }
      end

      r.on 'copy' do    # NEW
        check_auth!('orders', 'new')
        form_values = interactor.order_entity(id).to_h
        show_partial_or_page(r) { FinishedGoods::Orders::Order::New.call(form_values: form_values, remote: fetch?(r)) }
      end

      r.on 'close' do
        check_auth!('orders', 'edit')
        res = interactor.close_order(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect "/finished_goods/orders/orders/#{id}"
      end

      r.on 'reopen' do
        check_auth!('orders', 'edit')
        res = interactor.reopen_order(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect "/finished_goods/orders/orders/#{id}"
      end

      r.on 'refresh_order_lines' do
        check_auth!('orders', 'edit')
        res = interactor.refresh_order_lines(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect "/finished_goods/orders/orders/#{id}"
      end

      r.on 'create_load' do   # EDIT
        check_auth!('dispatch', 'new')
        form_values = interactor.order_entity(id).to_h
        show_partial_or_page(r) { FinishedGoods::Dispatch::Load::New.call(form_values: form_values, back_url: request.referer) }
      end

      r.on 'delete' do    # DELETE
        check_auth!('orders', 'delete')
        interactor.assert_permission!(:delete, id)
        res = interactor.delete_order(id)
        if res.success
          flash[:notice] = res.message
          r.redirect '/list/orders'
        else
          show_json_error(res.message, status: 200)
        end
      end

      r.is do
        r.get do       # SHOW
          check_auth!('orders', 'read')
          show_partial_or_page(r) { FinishedGoods::Orders::Order::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_order(id, params[:order])
          if res.success
            redirect_via_json "/finished_goods/orders/orders/#{id}"
          else
            re_show_form(r, res) { FinishedGoods::Orders::Order::Edit.call(id, form_values: params[:order], form_errors: res.errors) }
          end
        end
      end
    end

    r.on 'orders' do
      interactor = FinishedGoodsApp::OrderInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'change', String, String do |change_mode, change_field|
        handle_ui_change(:order, change_mode.to_sym, params, { field: change_field.to_sym })
      end

      r.on 'new' do    # NEW
        check_auth!('orders', 'new')
        show_partial_or_page(r) { FinishedGoods::Orders::Order::New.call(remote: fetch?(r)) }
      end

      r.post do        # CREATE
        res = interactor.create_order(params[:order])
        if res.success
          redirect_via_json "/finished_goods/orders/orders/#{res.instance.id}"
        else
          re_show_form(r, res, url: '/finished_goods/orders/orders/new') do
            FinishedGoods::Orders::Order::New.call(form_values: params[:order],
                                                   form_errors: res.errors,
                                                   remote: fetch?(r))
          end
        end
      end
    end

    # ORDER ITEMS
    # --------------------------------------------------------------------------
    r.on 'order_items', Integer do |id|
      interactor = FinishedGoodsApp::OrderItemInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:order_items, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('orders', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { FinishedGoods::Orders::OrderItem::Edit.call(id) }
      end

      r.on 'inline_edit' do
        res = interactor.inline_update_order_item(id, params)
        if res.success
          row_keys = %i[
            carton_quantity
            price_per_carton
            price_per_kg
          ]
          update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
        else
          undo_grid_inline_edit(message: res.message, message_type: :error)
        end
      end

      r.is do
        r.get do       # SHOW
          check_auth!('orders', 'read')
          show_partial { FinishedGoods::Orders::OrderItem::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_order_item(id, params[:order_item])
          if res.success
            row_keys = %i[
              order_id
              commodity_id
              commodity
              basic_pack_id
              basic_pack
              standard_pack_id
              standard_pack
              actual_count_id
              actual_count
              size_reference_id
              size_reference
              grade_id
              grade
              mark_id
              mark
              marketing_variety_id
              marketing_variety
              inventory_id
              inventory
              carton_quantity
              price_per_carton
              price_per_kg
              sell_by_code
              pallet_format_id
              pallet_format
              pm_mark_id
              pkg_mark
              pm_bom_id
              pkg_bom
              rmt_class_id
              rmt_class
              treatment_id
              treatment
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { FinishedGoods::Orders::OrderItem::Edit.call(id, form_values: params[:order_item], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('orders', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_order_item(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'order_items' do
      interactor = FinishedGoodsApp::OrderItemInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'change', String, String do |change_mode, change_field|
        handle_ui_change(:order_item, change_mode.to_sym, params, { field: change_field.to_sym })
      end

      r.on 'new' do    # NEW
        check_auth!('orders', 'new')
        show_partial_or_page(r) { FinishedGoods::Orders::OrderItem::New.call(form_values: params, remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_order_item(params[:order_item])
        if res.success
          redirect_via_json "/finished_goods/orders/orders/#{res.instance.order_id}"
        else
          re_show_form(r, res, url: '/finished_goods/orders/order_items/new') do
            FinishedGoods::Orders::OrderItem::New.call(form_values: params[:order_item],
                                                       form_errors: res.errors,
                                                       remote: fetch?(r))
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength, Metrics/ClassLength
