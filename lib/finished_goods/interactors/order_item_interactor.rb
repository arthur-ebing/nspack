# frozen_string_literal: true

module FinishedGoodsApp
  class OrderItemInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_order_item(params)
      res = validate_order_item_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_order_item(res)
        log_status(:order_items, id, 'CREATED')
        log_transaction
      end
      instance = order_item(id)
      success_response("Created order item #{instance.id}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { sell_by_code: ['This order item already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_order_item(id, params)
      res = validate_order_item_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_order_item(id, res)
        log_transaction
      end
      instance = order_item(id)
      success_response("Updated order item #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def allocate_to_order_item(id, load_id, params)
      repo.transaction do
        check!(:edit, id)
        repo.allocate_to_order_item(id, load_id, params, @user)

        log_transaction
      end

      instance = order_item(id)
      success_response('Updated order item', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def inline_update_order_item(id, params)
      repo.transaction do
        check!(:edit, id)
        repo.inline_update_order_item(id, params)

        log_transaction
      end

      instance = order_item(id)
      success_response('Updated order item', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_order_item(id)
      name = order_item(id).id
      repo.transaction do
        repo.delete_order_item(id)
        log_status(:order_items, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted order item #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete order item. It is still referenced#{e.message.partition('referenced').last}")
    end

    def stock_pallets_grid(ids, load_id)
      pallet_ids = repo.find_pallets_for_order_items(ids, load_id)
      rpt = dataminer_report('stock_pallets_for_loads.yml', conditions: [{ col: 'vw_pallets.pallet_id', op: 'IN', val: pallet_ids }])

      row_defs = dataminer_report_rows(rpt)
      {
        multiselect_ids: repo.select_values(:pallets, :id, load_id: load_id),
        columnDefs: col_defs_for_allocate_grid(rpt),
        rowDefs: row_defs
      }.to_json
    end

    def col_defs_for_allocate_grid(rpt)
      Crossbeams::DataGrid::ColumnDefiner.new(for_multiselect: true).make_columns do |mk|
        mk.action_column do |act|
          act.popup_view_link '/list/stock_pallet_sequences/with_params?key=standard&pallet_id=$col1$',
                              col1: 'id',
                              icon: 'list',
                              text: 'sequences',
                              title: 'Pallet sequences for Pallet No $:pallet_number$'
        end
        dataminer_report_columns(mk, rpt)
      end
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::OrderItem.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def check!(task, id = nil)
      res = TaskPermissionCheck::OrderItem.call(task, id)
      raise Crossbeams::InfoError, res.message unless res.success
    end

    private

    def repo
      @repo ||= OrderRepo.new
    end

    def order_item(id)
      repo.find_order_item(id)
    end

    def validate_order_item_params(params)
      OrderItemSchema.call(params)
    end
  end
end
