# frozen_string_literal: true

module MasterfilesApp
  class VesselInteractor < BaseInteractor
    def create_vessel(params) # rubocop:disable Metrics/AbcSize
      res = validate_vessel_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_vessel(res)
        log_transaction
      end
      instance = vessel(id)
      success_response("Created vessel #{instance.vessel_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { vessel_code: ['This vessel already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_vessel(id, params)
      res = validate_vessel_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_vessel(id, res)
        log_transaction
      end
      instance = vessel(id)
      success_response("Updated vessel #{instance.vessel_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_vessel(id)
      name = vessel(id).vessel_code
      repo.transaction do
        repo.delete_vessel(id)
        log_transaction
      end
      success_response("Deleted vessel #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Vessel.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= VesselRepo.new
    end

    def vessel(id)
      repo.find_vessel_flat(id)
    end

    def validate_vessel_params(params)
      VesselSchema.call(params)
    end
  end
end
