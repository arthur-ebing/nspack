# frozen_string_literal: true

module MasterfilesApp
  class VoyageTypeInteractor < BaseInteractor
    def create_voyage_type(params) # rubocop:disable Metrics/AbcSize
      res = validate_voyage_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_voyage_type(res)
        log_transaction
      end
      instance = voyage_type(id)
      success_response("Created voyage type #{instance.voyage_type_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { voyage_type_code: ['This voyage type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_voyage_type(id, params)
      res = validate_voyage_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_voyage_type(id, res)
        log_transaction
      end
      instance = voyage_type(id)
      success_response("Updated voyage type #{instance.voyage_type_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_voyage_type(id)
      name = voyage_type(id).voyage_type_code
      repo.transaction do
        repo.delete_voyage_type(id)
        log_transaction
      end
      success_response("Deleted voyage type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::VoyageType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= VoyageTypeRepo.new
    end

    def voyage_type(id)
      repo.find_voyage_type(id)
    end

    def validate_voyage_type_params(params)
      VoyageTypeSchema.call(params)
    end
  end
end
