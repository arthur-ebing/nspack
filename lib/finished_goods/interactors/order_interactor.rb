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

      val = validate_order_pallets(id, params)
      return val unless val.success

      repo.transaction do
        update_order_pallets(val) if params[:apply_changes_to_pallets] == 't'
        repo.update_order(id, res)

        log_transaction
      end
      instance = order_entity(id)
      success_response("Updated order #{instance.internal_order_number}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def changed_values(order_id, params)
      valid_fields = %i[packed_tm_group_id target_customer_party_role_id]
      new_values = params.to_h.slice(*valid_fields).transform_values { |v| v.nil_or_empty? ? nil : v.to_i }
      current_values = repo.find_hash(:orders, order_id).to_h.slice(*valid_fields)
      Hash[*(new_values.to_a - current_values.to_a).flatten].compact
    end

    def validate_order_pallets(order_id, params)
      difference = changed_values(order_id, params)
      return ok_response if difference.empty?

      order_item_ids = repo.select_values(:order_items, :id, order_id: order_id)
      pallet_ids = repo.select_values(:pallet_sequences, :pallet_id, order_item_id: order_item_ids).uniq
      return success_response('ok', OpenStruct.new(pallet_ids: pallet_ids, params: difference)) if params[:apply_changes_to_pallets] == 't'

      # Raises validation response to get user consent of transaction
      message = "Additionally #{pallet_ids.length} pallets will be updated! This cannot be undone."
      validation_failed_response({ messages: { apply_changes_to_pallets: [message] }, apply_changes_to_pallets: false })
    end

    def update_order_pallets(res)
      instance = res.instance
      ids = repo.select_values(:pallet_sequences, :id, pallet_id: instance.pallet_ids).uniq
      repo.update(:pallet_sequences, ids, instance.params)
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
      load_ids = repo.select_values(:orders_loads, :load_id, order_id: id)

      Crossbeams::DataGrid::ColumnDefiner.new(for_multiselect: for_multiselect).make_columns do |mk| # rubocop:disable Metrics/BlockLength
        mk.action_column do |act| # rubocop:disable Metrics/BlockLength
          act.popup_view_link '/finished_goods/orders/order_items/$col1$',
                              col1: 'id', icon: 'view-show', text: 'view', title: 'View'
          act.popup_edit_link '/finished_goods/orders/order_items/$col1$/edit',
                              col1: 'id', icon: 'edit', text: 'edit', title: 'Edit', hide_if_true: 'pallets_allocated'
          act.popup_delete_link '/finished_goods/orders/order_items/$col1$',
                                col1: 'id', icon: 'delete', text: 'delete'
          if load_ids.length == 1
            act.popup_view_link "/finished_goods/orders/order_items/$col1$/allocate/#{load_ids.first}",
                                col1: 'id', icon: 'edit', text: 'allocate pallets', title: 'Allocate Pallets'
          else
            act.popup_view_link '/finished_goods/orders/order_items/$col1$/allocate',
                                col1: 'id', icon: 'edit', text: 'allocate to load', title: 'Loads'
          end
          act.separator
          url = '/list/order_item_prices/with_params?key=standard'
          options = { icon: 'edit', text: 'previous prices', title: 'Previous prices for Order Item' }
          columns = %w[commodity_id basic_pack_id standard_pack_id actual_count_id size_reference_id
                       inventory_id grade_id mark_id marketing_variety_id sell_by_code
                       pallet_format_id pm_mark_id pm_bom_id rmt_class_id order_id]

          columns.each_with_index do |val, index|
            count = index + 1
            options["col#{count}".to_sym] = val
            url = "#{url}&#{val}=$col#{count}$"
          end
          act.popup_view_link(url, options)
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
