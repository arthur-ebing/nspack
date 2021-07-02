# frozen_string_literal: true

module MasterfilesApp
  class CurrencyInteractor < BaseInteractor
    def create_currency(params)
      res = validate_currency_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_currency(res)
        log_status(:currencies, id, 'CREATED')
        log_transaction
      end
      instance = currency(id)
      success_response("Created currency #{instance.currency}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { currency: ['This currency already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_currency(id, params)
      res = validate_currency_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_currency(id, res)
        log_transaction
      end
      instance = currency(id)
      success_response("Updated currency #{instance.currency}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_currency(id)
      name = currency(id).currency
      repo.transaction do
        repo.delete_currency(id)
        log_status(:currencies, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted currency #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete currency. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Currency.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FinanceRepo.new
    end

    def currency(id)
      repo.find_currency(id)
    end

    def validate_currency_params(params)
      CurrencySchema.call(params)
    end
  end
end
