# frozen_string_literal: true

module MasterfilesApp
  class VehicleTypeInteractor < BaseInteractor
    def create_vehicle_type(params) # rubocop:disable Metrics/AbcSize
      res = validate_vehicle_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_vehicle_type(res)
        log_transaction
      end
      instance = vehicle_type(id)
      success_response("Created vehicle type #{instance.vehicle_type_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { vehicle_type_code: ['This vehicle type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_vehicle_type(id, params)
      res = validate_vehicle_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_vehicle_type(id, res)
        log_transaction
      end
      instance = vehicle_type(id)
      success_response("Updated vehicle type #{instance.vehicle_type_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_vehicle_type(id)
      name = vehicle_type(id).vehicle_type_code
      repo.transaction do
        repo.delete_vehicle_type(id)
        log_transaction
      end
      success_response("Deleted vehicle type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::VehicleType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= VehicleTypeRepo.new
    end

    def vehicle_type(id)
      repo.find_vehicle_type(id)
    end

    def validate_vehicle_type_params(params)
      VehicleTypeSchema.call(params)
    end
  end
end
