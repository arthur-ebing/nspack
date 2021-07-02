# frozen_string_literal: true

module ProductionApp
  class ResourceTypeInteractor < BaseInteractor
    def create_plant_resource_type(params)
      res = validate_plant_resource_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_plant_resource_type(res)
        log_status('plant_resource_types', id, 'CREATED')
        log_transaction
      end
      instance = plant_resource_type(id)
      success_response("Created plant resource type #{instance.plant_resource_type_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { plant_resource_type_code: ['This plant resource type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_plant_resource_type(id, params)
      res = validate_plant_resource_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_plant_resource_type(id, res)
        log_transaction
      end
      instance = plant_resource_type(id)
      success_response("Updated plant resource type #{instance.plant_resource_type_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_plant_resource_type(id)
      name = plant_resource_type(id).plant_resource_type_code
      repo.transaction do
        repo.delete_plant_resource_type(id)
        log_status('plant_resource_types', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted plant resource type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_system_resource_type(id)
      name = system_resource_type(id).system_resource_type_code
      repo.transaction do
        repo.delete_system_resource_type(id)
        log_status('system_resource_types', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted system resource type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    # def assert_permission!(task, id = nil)
    #   res = TaskPermissionCheck::ResourceType.call(task, id)
    #   raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    # end
    private

    def repo
      @repo ||= ResourceRepo.new
    end

    def plant_resource_type(id)
      repo.find_plant_resource_type(id)
    end

    def system_resource_type(id)
      repo.find_system_resource_type(id)
    end

    def validate_plant_resource_type_params(params)
      PlantResourceTypeSchema.call(params)
    end
  end
end
