# frozen_string_literal: true

module MasterfilesApp
  class CustomerPaymentTermInteractor < BaseInteractor
    def create_customer_payment_term(params)
      res = validate_customer_payment_term_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_customer_payment_term(res)
        log_status(:customer_payment_terms, id, 'CREATED')
        log_transaction
      end
      instance = customer_payment_term(id)
      success_response("Created customer payment term #{instance.id}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { id: ['This customer payment term already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_customer_payment_term(id, params)
      res = validate_customer_payment_term_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_customer_payment_term(id, res)
        log_transaction
      end
      instance = customer_payment_term(id)
      success_response("Updated customer payment term #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_customer_payment_term(id)
      name = customer_payment_term(id).id
      repo.transaction do
        repo.delete_customer_payment_term(id)
        log_status(:customer_payment_terms, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted customer payment term #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete customer payment term. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::CustomerPaymentTerm.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FinanceRepo.new
    end

    def customer_payment_term(id)
      repo.find_customer_payment_term(id)
    end

    def validate_customer_payment_term_params(params)
      CustomerPaymentTermSchema.call(params)
    end
  end
end
