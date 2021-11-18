# frozen_string_literal: true

module ProductionApp
  class WorkOrderInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_work_order(params) # rubocop:disable Metrics/AbcSize
      res = validate_work_order_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_work_order(res)
        log_status(:work_orders, id, 'CREATED')
        log_transaction
      end
      instance = repo.find_work_order_flat(id)
      success_response("Created work order #{instance[:id]}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { id: ['This work order already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_work_order(id, params)
      res = validate_work_order_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_work_order(id, res)
        log_transaction
      end
      instance = work_order(id)
      success_response("Updated work order #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_work_order(id) # rubocop:disable Metrics/AbcSize
      name = work_order(id).id
      repo.transaction do
        repo.delete_work_order(id)
        log_status(:work_orders, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted work order #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete work order. It is still referenced#{e.message.partition('referenced').last}")
    end

    def create_work_order_items(work_order_id, submitted_product_setup_ids, saved_setups, deselected_setup_templates) # rubocop:disable Metrics/AbcSize
      setups_deselected_from_templated_grid = repo.find_product_setups_for_work_order_by_product_setup_templates(work_order_id, deselected_setup_templates)
      saved_setups -= setups_deselected_from_templated_grid
      setups_deselected_from_setups_grid = (saved_setups - submitted_product_setup_ids)

      setups_to_be_deleted = setups_deselected_from_templated_grid + setups_deselected_from_setups_grid
      setups_to_be_created = submitted_product_setup_ids - saved_setups
      actions = []
      current_product_setup = nil
      repo.transaction do
        repo.select_values(:work_order_items, :id, work_order_id: work_order_id, product_setup_id: setups_to_be_deleted).each do |i|
          repo.delete_work_order_item(i)
          actions << OpenStruct.new(type: :delete_grid_row,
                                    id: i,
                                    grid_id: 'work_order_items')
        end

        setups_to_be_created.each do |p|
          current_product_setup = p
          id = repo.create_work_order_item(work_order_id: work_order_id, product_setup_id: p, pallet_fulfillment_warning_level: AppConst::CR_FG.wo_fulfillment_pallet_warning_level)
          log_status(:work_order_items, id, 'CREATED')
          log_transaction

          instance = repo.find_work_order_item_flat(id)
          actions << OpenStruct.new(type: :add_grid_row,
                                    attrs: instance)
        end
      end
      success_response('Created work orders created successfully', actions: actions)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { Work: ["order item:#{ProductionApp::ProductSetupRepo.new.find_product_setup(current_product_setup).product_setup_code} already exists"] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_work_order_item(id, column_name, column_value)
      res = validate_work_order_item_params({ column_name => column_value })
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_work_order_item(id, res)
        log_transaction
      end
      instance = repo.find_work_order_item(id)
      success_response("Updated work order item #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_work_order_item(id) # rubocop:disable Metrics/AbcSize
      name = repo.find_work_order_item(id).id
      repo.transaction do
        repo.delete_work_order_item(id)
        log_status(:work_order_items, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted work order item #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete work order item. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::WorkOrder.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def assert_work_order_item_permission!(task, id = nil)
      res = TaskPermissionCheck::WorkOrderItem.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= OrderRepo.new
    end

    def work_order(id)
      repo.find_work_order(id)
    end

    def validate_work_order_params(params)
      WorkOrderSchema.call(params)
    end

    def validate_work_order_item_params(params)
      WorkOrderItemSchema.call(params)
    end
  end
end
