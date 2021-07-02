# frozen_string_literal: true

module MasterfilesApp
  class PaymentTermTypeInteractor < BaseInteractor
    def create_payment_term_type(params)
      res = validate_payment_term_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_payment_term_type(res)
        log_status(:payment_term_types, id, 'CREATED')
        log_transaction
      end
      instance = payment_term_type(id)
      success_response("Created payment term type #{instance.payment_term_type}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { payment_term_type: ['This payment term type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_payment_term_type(id, params)
      res = validate_payment_term_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_payment_term_type(id, res)
        log_transaction
      end
      instance = payment_term_type(id)
      success_response("Updated payment term type #{instance.payment_term_type}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_payment_term_type(id)
      name = payment_term_type(id).payment_term_type
      repo.transaction do
        repo.delete_payment_term_type(id)
        log_status(:payment_term_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted payment term type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete payment term type. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PaymentTermType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FinanceRepo.new
    end

    def payment_term_type(id)
      repo.find_payment_term_type(id)
    end

    def validate_payment_term_type_params(params)
      PaymentTermTypeSchema.call(params)
    end
  end
end
