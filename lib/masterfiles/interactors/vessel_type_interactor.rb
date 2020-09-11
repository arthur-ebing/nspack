# frozen_string_literal: true

module MasterfilesApp
  class VesselTypeInteractor < BaseInteractor
    def create_vessel_type(params) # rubocop:disable Metrics/AbcSize
      res = validate_vessel_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_vessel_type(res)
        log_transaction
      end
      instance = vessel_type(id)
      success_response("Created vessel type #{instance.vessel_type_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { vessel_type_code: ['This vessel type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_vessel_type(id, params)
      res = validate_vessel_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_vessel_type(id, res)
        log_transaction
      end
      instance = vessel_type(id)
      success_response("Updated vessel type #{instance.vessel_type_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_vessel_type(id)
      name = vessel_type(id).vessel_type_code
      repo.transaction do
        repo.delete_vessel_type(id)
        log_transaction
      end
      success_response("Deleted vessel type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::VesselType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= VesselTypeRepo.new
    end

    def vessel_type(id)
      repo.find_vessel_type_flat(id)
    end

    def validate_vessel_type_params(params)
      VesselTypeSchema.call(params)
    end
  end
end
