# frozen_string_literal: true

module MasterfilesApp
  class WageLevelInteractor < BaseInteractor
    def create_wage_level(params) # rubocop:disable Metrics/AbcSize
      res = validate_wage_level_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_wage_level(res)
        log_status(:wage_levels, id, 'CREATED')
        log_transaction
      end
      instance = wage_level(id)
      success_response("Created wage level #{instance.description}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { description: ['This wage level already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_wage_level(id, params)
      res = validate_wage_level_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_wage_level(id, res)
        log_transaction
      end
      instance = wage_level(id)
      success_response("Updated wage level #{instance.description}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_wage_level(id)
      name = wage_level(id).description
      repo.transaction do
        repo.delete_wage_level(id)
        log_status(:wage_levels, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted wage level #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::WageLevel.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= HumanResourcesRepo.new
    end

    def wage_level(id)
      repo.find_wage_level(id)
    end

    def validate_wage_level_params(params)
      WageLevelSchema.call(params)
    end
  end
end
