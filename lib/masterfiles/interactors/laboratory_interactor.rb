# frozen_string_literal: true

module MasterfilesApp
  class LaboratoryInteractor < BaseInteractor
    def create_laboratory(params)
      res = validate_laboratory_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_laboratory(res)
        log_status(:laboratories, id, 'CREATED')
        log_transaction
      end
      instance = laboratory(id)
      success_response("Created laboratory #{instance.lab_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { lab_code: ['This laboratory already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_laboratory(id, params)
      res = validate_laboratory_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_laboratory(id, res)
        log_transaction
      end
      instance = laboratory(id)
      success_response("Updated laboratory #{instance.lab_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_laboratory(id) # rubocop:disable Metrics/AbcSize
      name = laboratory(id).lab_code
      repo.transaction do
        repo.delete_laboratory(id)
        log_status(:laboratories, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted laboratory #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete laboratory. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Laboratory.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= QualityRepo.new
    end

    def laboratory(id)
      repo.find_laboratory(id)
    end

    def validate_laboratory_params(params)
      LaboratorySchema.call(params)
    end
  end
end
