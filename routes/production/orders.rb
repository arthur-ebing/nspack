# frozen_string_literal: true

class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'orders', 'production' do |r| # rubocop:disable Metrics/BlockLength
    # MARKETING ORDERS
    # --------------------------------------------------------------------------
    r.on 'marketing_orders', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = ProductionApp::OrderInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:marketing_orders, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        # check_auth!('orders', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { Production::Orders::MarketingOrder::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('orders', 'read')
          show_partial_or_page(r) { Production::Orders::MarketingOrder::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_marketing_order(id, params[:marketing_order])
          if res.success
            # show_partial(notice: 'Marketing Order Updated') { Production::Orders::MarketingOrder::Edit.call(id) }
            flash[:notice] = 'Marketing Order Updated Successfully'
            r.redirect("/production/orders/marketing_orders/#{id}/edit")
          else
            re_show_form(r, res) { Production::Orders::MarketingOrder::Edit.call(id, form_values: params[:marketing_order], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('orders', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_marketing_order(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'marketing_orders' do
      interactor = ProductionApp::OrderInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        # check_auth!('orders', 'new')
        show_partial_or_page(r) { Production::Orders::MarketingOrder::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_marketing_order(params[:marketing_order])
        if res.success
          flash[:notice] = 'Marketing Order Created Successfully'
          r.redirect("/production/orders/marketing_orders/#{res[:instance][:id]}/edit")
        else
          re_show_form(r, res, url: '/production/orders/marketing_orders/new') do
            Production::Orders::MarketingOrder::New.call(form_values: params[:marketing_order],
                                                         form_errors: res.errors,
                                                         remote: fetch?(r))
          end
        end
      end

      r.on 'completed_marketing_orders' do
        r.redirect('/list/marketing_orders/with_params?key=completed')
      end
    end

    # WORK ORDERS
    # --------------------------------------------------------------------------
    r.on 'work_orders', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = ProductionApp::WorkOrderInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:work_orders, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('orders', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { Production::Orders::WorkOrder::Edit.call(id) }
      end

      r.on 'manage_items' do
        r.get do
          selected_templates = ProductionApp::OrderRepo.new.find_work_order_product_setup_templates(id)
          store_locally(:saved_setup_templates, selected_templates)
          r.redirect("/list/work_order_items_setup_templates/multi?key=standard&id=#{id}&work_order_item_templates=#{selected_templates.empty? ? 0 : selected_templates.join(',')}")
        end

        r.post do
          selection = multiselect_grid_choices(params)
          selected_setups = ProductionApp::OrderRepo.new.select_values(:work_order_items, :product_setup_id, work_order_id: id)
          store_locally(:saved_setups, selected_setups)
          store_locally(:deselected_setup_templates, retrieve_from_local_store(:saved_setup_templates) - selection)
          r.redirect("/list/work_order_items_setups/multi?key=standard&id=#{id}&template_ids=#{selection.join(',')}&work_order_item_setups=#{selected_setups.empty? ? 0 : selected_setups.join(',')}")
        end
      end

      r.on 'create_work_order_items_submit' do
        res = interactor.create_work_order_items(id, retrieve_from_local_store(:submitted_work_order_items), retrieve_from_local_store(:saved_setups), retrieve_from_local_store(:deselected_setup_templates))
        if res.success
          json_actions(res.instance[:actions],
                       res.message,
                       keep_dialog_open: false)
        else
          show_error(unwrap_failed_response(res), fetch?(r))
        end
      end

      r.on 'create_work_order_items' do
        deselected_setup_templates = retrieve_from_local_store(:deselected_setup_templates)
        store_locally(:deselected_setup_templates, deselected_setup_templates)
        store_locally(:submitted_work_order_items, multiselect_grid_choices(params))
        if !deselected_setup_templates.empty?
          show_partial_or_page(r) { Production::Orders::WorkOrder::Confirm.call(id, deselected_setup_templates) }
        else
          r.redirect("/production/orders/work_orders/#{id}/create_work_order_items_submit")
        end
      end

      r.is do
        r.get do       # SHOW
          check_auth!('orders', 'read')
          show_partial { Production::Orders::WorkOrder::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_work_order(id, params[:work_order])
          if res.success
            flash[:notice] = 'Work Order Updated Successfully'
            r.redirect("/production/orders/work_orders/#{id}/edit")
          else
            re_show_form(r, res) { Production::Orders::WorkOrder::Edit.call(id, form_values: params[:work_order], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('orders', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_work_order(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'work_orders' do
      interactor = ProductionApp::WorkOrderInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('orders', 'new')
        show_partial_or_page(r) { Production::Orders::WorkOrder::New.call(remote: fetch?(r)) }
      end

      r.post do        # CREATE
        res = interactor.create_work_order(params[:work_order])
        if res.success
          flash[:notice] = 'Marketing Order Created Successfully'
          r.redirect("/production/orders/work_orders/#{res[:instance][:id]}/edit")
        else
          re_show_form(r, res, url: '/production/orders/work_orders/new') do
            Production::Orders::WorkOrder::New.call(form_values: params[:work_order],
                                                    form_errors: res.errors,
                                                    remote: fetch?(r))
          end
        end
      end

      r.on 'completed_work_orders' do
        r.redirect('/list/work_orders/with_params?key=completed')
      end
    end

    # WORK ORDER ITEMS
    # --------------------------------------------------------------------------
    r.on 'work_order_items', Integer do |id|
      interactor = ProductionApp::WorkOrderInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:work_order_items, id) do
        handle_not_found(r)
      end

      r.post do     # UPDATE
        res = interactor.update_work_order_item(id, params[:column_name], params[:column_value])
        if res.success
          blank_json_response
        else
          undo_grid_inline_edit(message: res.message, message_type: :warning)
        end
      end
    end
  end
end
