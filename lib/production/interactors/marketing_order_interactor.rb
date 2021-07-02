# frozen_string_literal: true

module ProductionApp
  class OrderInteractor < BaseInteractor
    def create_marketing_order(params)
      res = validate_marketing_order_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_marketing_order(res)
        log_status(:marketing_orders, id, 'CREATED')
        log_transaction
      end
      instance = marketing_order(id)
      success_response("Created marketing order #{instance.order_number}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { order_number: ['This marketing order already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_marketing_order(id, params)
      res = validate_marketing_order_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_marketing_order(id, res)
        log_transaction
      end
      instance = marketing_order(id)
      success_response("Updated marketing order #{instance.order_number}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_marketing_order(id) # rubocop:disable Metrics/AbcSize
      name = marketing_order(id).order_number
      repo.transaction do
        repo.delete_marketing_order(id)
        log_status(:marketing_orders, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted marketing order #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete marketing order. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::MarketingOrder.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= OrderRepo.new
    end

    def marketing_order(id)
      repo.find_marketing_order(id)
    end

    def validate_marketing_order_params(params)
      MarketingOrderSchema.call(params)
    end
  end
end
