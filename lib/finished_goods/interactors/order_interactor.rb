# frozen_string_literal: true

module FinishedGoodsApp
  class OrderInteractor < BaseInteractor
    def create_order(params) # rubocop:disable Metrics/AbcSize
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

    def update_order(id, params)
      res = validate_order_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_order(id, res)
        log_transaction
      end
      instance = order_entity(id)
      success_response("Updated order #{instance.internal_order_number}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_order(id) # rubocop:disable Metrics/AbcSize
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
