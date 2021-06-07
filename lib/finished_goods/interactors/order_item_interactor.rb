# frozen_string_literal: true

module FinishedGoodsApp
  class OrderItemInteractor < BaseInteractor
    def create_order_item(params) # rubocop:disable Metrics/AbcSize
      res = validate_order_item_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_order_item(res)
        log_status(:order_items, id, 'CREATED')
        log_transaction
      end
      instance = order_item(id)
      success_response("Created order item #{instance.sell_by_code}", instance)
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
      success_response("Updated order item #{instance.sell_by_code}", instance)
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

    def delete_order_item(id) # rubocop:disable Metrics/AbcSize
      name = order_item(id).sell_by_code
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
