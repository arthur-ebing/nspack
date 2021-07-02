# frozen_string_literal: true

module MasterfilesApp
  class OrderTypeInteractor < BaseInteractor
    def create_order_type(params)
      res = validate_order_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_order_type(res)
        log_status(:order_types, id, 'CREATED')
        log_transaction
      end
      instance = order_type(id)
      success_response("Created order type #{instance.order_type}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { order_type: ['This order type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_order_type(id, params)
      res = validate_order_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_order_type(id, res)
        log_transaction
      end
      instance = order_type(id)
      success_response("Updated order type #{instance.order_type}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_order_type(id) # rubocop:disable Metrics/AbcSize
      name = order_type(id).order_type
      repo.transaction do
        repo.delete_order_type(id)
        log_status(:order_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted order type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete order type. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::OrderType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FinanceRepo.new
    end

    def order_type(id)
      repo.find_order_type(id)
    end

    def validate_order_type_params(params)
      OrderTypeSchema.call(params)
    end
  end
end
