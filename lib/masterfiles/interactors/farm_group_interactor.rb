# frozen_string_literal: true

module MasterfilesApp
  class FarmGroupInteractor < BaseInteractor
    def create_farm_group(params) # rubocop:disable Metrics/AbcSize
      res = validate_farm_group_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_farm_group(res)
        log_status('farm_groups', id, 'CREATED')
        log_transaction
      end
      instance = farm_group(id)
      success_response("Created farm group #{instance.farm_group_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { farm_group_code: ['This farm group already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_farm_group(id, params)
      res = validate_farm_group_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_farm_group(id, res)
        log_transaction
      end
      instance = farm_group(id)
      success_response("Updated farm group #{instance.farm_group_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_farm_group(id)
      name = farm_group(id).farm_group_code
      repo.transaction do
        repo.delete_farm_group(id)
        log_status('farm_groups', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted farm group #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::FarmGroup.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FarmRepo.new
    end

    def farm_group(id)
      repo.find_farm_group(id)
    end

    def validate_farm_group_params(params)
      FarmGroupSchema.call(params)
    end
  end
end
