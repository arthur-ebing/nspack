# frozen_string_literal: true

module MasterfilesApp
  class PmBomInteractor < BaseInteractor
    def create_pm_bom(params) # rubocop:disable Metrics/AbcSize
      res = validate_pm_bom_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_pm_bom(res)
        log_status('pm_boms', id, 'CREATED')
        log_transaction
      end
      instance = pm_bom(id)
      success_response("Created pm bom #{instance.bom_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { bom_code: ['This pm bom already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_pm_bom(id, params)
      res = validate_pm_bom_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_pm_bom(id, res)
        log_transaction
      end
      instance = pm_bom(id)
      success_response("Updated pm bom #{instance.bom_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_pm_bom(id)
      name = pm_bom(id).bom_code
      repo.transaction do
        repo.delete_pm_bom(id)
        log_status('pm_boms', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted pm bom #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PmBom.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= BomsRepo.new
    end

    def pm_bom(id)
      repo.find_pm_bom(id)
    end

    def validate_pm_bom_params(params)
      PmBomSchema.call(params)
    end
  end
end
