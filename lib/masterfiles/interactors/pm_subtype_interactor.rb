# frozen_string_literal: true

module MasterfilesApp
  class PmSubtypeInteractor < BaseInteractor
    def create_pm_subtype(params) # rubocop:disable Metrics/AbcSize
      res = validate_pm_subtype_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_pm_subtype(res)
        log_status('pm_subtypes', id, 'CREATED')
        log_transaction
      end
      instance = pm_subtype(id)
      success_response("Created pm subtype #{instance.subtype_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { subtype_code: ['This pm subtype already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_pm_subtype(id, params)
      res = validate_pm_subtype_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_pm_subtype(id, res)
        log_transaction
      end
      instance = pm_subtype(id)
      success_response("Updated pm subtype #{instance.subtype_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_pm_subtype(id)
      name = pm_subtype(id).subtype_code
      repo.transaction do
        repo.delete_pm_subtype(id)
        log_status('pm_subtypes', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted pm subtype #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PmSubtype.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= BomsRepo.new
    end

    def pm_subtype(id)
      repo.find_pm_subtype(id)
    end

    def validate_pm_subtype_params(params)
      PmSubtypeSchema.call(params)
    end
  end
end
