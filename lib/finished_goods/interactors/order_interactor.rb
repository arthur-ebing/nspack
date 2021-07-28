# frozen_string_literal: true

module FinishedGoodsApp
  class OrderInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_order(params)
      res = validate_order_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_order(res)
        log_status(:orders, id, 'CREATED')
        log_transaction
      end
      instance = order_entity(id)
      success_response("Created order #{instance.internal_order_number}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { internal_order_number: ['This order already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_order(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_order_params(params)
      return validation_failed_response(res) if res.failure?

      args = res.to_h
      res = update_order_pallets(id, args)
      return res unless res.success

      repo.transaction do
        update_order_pallets(id, args)
        repo.update_order(id, args)

        log_transaction
      end
      instance = order_entity(id)
      success_response("Updated order #{instance.internal_order_number}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_order(id)
      name = order_entity(id).internal_order_number
      repo.transaction do
        repo.delete_order(id)
        log_status(:orders, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted order #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete order. It is still referenced#{e.message.partition('referenced').last}")
    end

    def close_order(id)
      repo.transaction do
        repo.update_order(id, allocated: true)
        log_transaction
      end
      instance = order_entity(id)
      success_response("Closed order #{instance.internal_order_number}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def reopen_order(id)
      repo.transaction do
        repo.update_order(id, allocated: false)
        log_transaction
      end
      instance = order_entity(id)
      success_response("Reopened order #{instance.internal_order_number}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def refresh_order_lines(id)
      repo.transaction do
        FinishedGoodsApp::ProcessOrderLines.call(@user, order_id: id)
        log_transaction
      end
      instance = order_entity(id)
      success_response("Created order lines for #{instance.internal_order_number}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_order_pallets(order_id, params) # rubocop:disable Metrics/AbcSize
      commit = params.delete(:commit)
      valid_fields = %i[packed_tm_group_id target_customer_party_role_id]

      new_values = params.clone.slice(*valid_fields)
      current_values = DB[:orders].where(id: order_id).select(*valid_fields).first
      return ok_response if current_values == new_values

      pallet_ids = DB[:pallet_sequences].join(:order_items, id: :order_item_id).where(order_id: order_id).distinct.select_map(:pallet_id)
      return ok_response if pallet_ids.empty?

      message = "Additionally #{pallet_ids.uniq.length} pallets will be updated! This cannot be undone."
      return validation_failed_response({ messages: { commit: [message] }, commit: false }) unless commit

      update_values = new_values.compact
      DB[:pallet_sequences].where(pallet_id: pallet_ids).update(update_values) unless update_values.empty?
      ok_response
    end

    def order_items_grid(id, params)
      rpt = dataminer_report('order_items.yml', conditions: [{ col: 'order_items.order_id', op: '=', val: id }])
      row_defs = dataminer_report_rows(rpt)
      {
        fieldUpdateUrl: '/finished_goods/orders/order_items/$:id$/inline_edit',
        columnDefs: col_defs(rpt, id, params[:for_multiselect]),
        rowDefs: row_defs
      }.to_json
    end

    def col_defs(rpt, id, for_multiselect = false) # rubocop:disable Metrics/AbcSize
      pricing_per_kg = repo.get(:orders, id, :pricing_per_kg)
      loads = repo.select_values(:orders_loads, :load_id, order_id: id)

      Crossbeams::DataGrid::ColumnDefiner.new(for_multiselect: for_multiselect).make_columns do |mk| # rubocop:disable Metrics/BlockLength
        mk.action_column do |act|
          act.popup_view_link '/finished_goods/orders/order_items/$col1$',
                              col1: 'id', icon: 'view-show', text: 'view', title: 'View'
          act.popup_edit_link '/finished_goods/orders/order_items/$col1$/edit',
                              col1: 'id', icon: 'edit', text: 'edit', title: 'Edit', hide_if_true: 'pallets_allocated'
          act.popup_delete_link '/finished_goods/orders/order_items/$col1$',
                                col1: 'id', icon: 'delete', text: 'delete'
          if loads.length == 1
            act.popup_view_link "/finished_goods/orders/order_items/$col1$/allocate/#{loads.first}",
                                col1: 'id', icon: 'edit', text: 'allocate pallets', title: 'Allocate Pallets'
          else
            act.popup_view_link '/finished_goods/orders/order_items/$col1$/allocate',
                                col1: 'id', icon: 'edit', text: 'allocate to load', title: 'Loads'
          end
          act.separator
          act.popup_view_link '/development/statuses/list/order_items/$col1$',
                              col1: 'id', icon: 'information-solid', text: 'status', title: 'Status'
        end
        rpt.ordered_columns.each do |column|
          if %w[carton_quantity price_per_carton price_per_kg].include? column.name
            hide = (column.name == 'price_per_kg' && !pricing_per_kg) || (column.name == 'price_per_carton' && pricing_per_kg)
            mk.col(column.name, column.caption, { width: column.width, data_type: column.data_type, editable: true, cellEditor: 'numericCellEditor', hide: hide })
            next
          end
          mk.column_from_dataminer column
        end
      end
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Order.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def order_entity(id)
      repo.find_order(id)
    end

    private

    def repo
      @repo ||= OrderRepo.new
    end

    def validate_order_params(params)
      OrderSchema.call(params)
    end
  end
end
