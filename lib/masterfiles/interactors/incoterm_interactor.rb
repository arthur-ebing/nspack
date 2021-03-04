# frozen_string_literal: true

module MasterfilesApp
  class IncotermInteractor < BaseInteractor
    def create_incoterm(params) # rubocop:disable Metrics/AbcSize
      res = validate_incoterm_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_incoterm(res)
        log_status(:incoterms, id, 'CREATED')
        log_transaction
      end
      instance = incoterm(id)
      success_response("Created incoterm #{instance.incoterm}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { incoterm: ['This incoterm already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_incoterm(id, params)
      res = validate_incoterm_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_incoterm(id, res)
        log_transaction
      end
      instance = incoterm(id)
      success_response("Updated incoterm #{instance.incoterm}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_incoterm(id) # rubocop:disable Metrics/AbcSize
      name = incoterm(id).incoterm
      repo.transaction do
        repo.delete_incoterm(id)
        log_status(:incoterms, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted incoterm #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete incoterm. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Incoterm.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FinanceRepo.new
    end

    def incoterm(id)
      repo.find_incoterm(id)
    end

    def validate_incoterm_params(params)
      IncotermSchema.call(params)
    end
  end
end
