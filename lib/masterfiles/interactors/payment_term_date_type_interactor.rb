# frozen_string_literal: true

module MasterfilesApp
  class PaymentTermDateTypeInteractor < BaseInteractor
    def create_payment_term_date_type(params)
      res = validate_payment_term_date_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_payment_term_date_type(res)
        log_status(:payment_term_date_types, id, 'CREATED')
        log_transaction
      end
      instance = payment_term_date_type(id)
      success_response("Created payment term date type #{instance.type_of_date}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { type_of_date: ['This payment term date type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_payment_term_date_type(id, params)
      res = validate_payment_term_date_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_payment_term_date_type(id, res)
        log_transaction
      end
      instance = payment_term_date_type(id)
      success_response("Updated payment term date type #{instance.type_of_date}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_payment_term_date_type(id)
      name = payment_term_date_type(id).type_of_date
      repo.transaction do
        repo.delete_payment_term_date_type(id)
        log_status(:payment_term_date_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted payment term date type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete payment term date type. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PaymentTermDateType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FinanceRepo.new
    end

    def payment_term_date_type(id)
      repo.find_payment_term_date_type(id)
    end

    def validate_payment_term_date_type_params(params)
      PaymentTermDateTypeSchema.call(params)
    end
  end
end
