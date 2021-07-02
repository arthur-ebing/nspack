# frozen_string_literal: true

module MasterfilesApp
  class DealTypeInteractor < BaseInteractor
    def create_deal_type(params)
      res = validate_deal_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_deal_type(res)
        log_status(:deal_types, id, 'CREATED')
        log_transaction
      end
      instance = deal_type(id)
      success_response("Created deal type #{instance.deal_type}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { deal_type: ['This deal type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_deal_type(id, params)
      res = validate_deal_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_deal_type(id, res)
        log_transaction
      end
      instance = deal_type(id)
      success_response("Updated deal type #{instance.deal_type}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_deal_type(id)
      name = deal_type(id).deal_type
      repo.transaction do
        repo.delete_deal_type(id)
        log_status(:deal_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted deal type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete deal type. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::DealType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FinanceRepo.new
    end

    def deal_type(id)
      repo.find_deal_type(id)
    end

    def validate_deal_type_params(params)
      DealTypeSchema.call(params)
    end
  end
end
