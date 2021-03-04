# frozen_string_literal: true

module MasterfilesApp
  class PaymentTermInteractor < BaseInteractor
    def create_payment_term(params) # rubocop:disable Metrics/AbcSize
      res = validate_payment_term_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_payment_term(res)
        log_status(:payment_terms, id, 'CREATED')
        log_transaction
      end
      instance = payment_term(id)
      success_response("Created payment term #{instance.short_description}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { short_description: ['This payment term already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_payment_term(id, params)
      res = validate_payment_term_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_payment_term(id, res)
        log_transaction
      end
      instance = payment_term(id)
      success_response("Updated payment term #{instance.short_description}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_payment_term(id) # rubocop:disable Metrics/AbcSize
      name = payment_term(id).short_description
      repo.transaction do
        repo.delete_payment_term(id)
        log_status(:payment_terms, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted payment term #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete payment term. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PaymentTerm.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FinanceRepo.new
    end

    def payment_term(id)
      repo.find_payment_term(id)
    end

    def validate_payment_term_params(params)
      PaymentTermSchema.call(params)
    end
  end
end
