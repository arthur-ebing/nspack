# frozen_string_literal: true

module MasterfilesApp
  class DepotInteractor < BaseInteractor
    def create_depot(params)
      res = validate_depot_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_depot(res)
      end
      instance = depot(id)
      success_response("Created depot #{instance.depot_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { depot_code: ['This depot already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_depot(id, params)
      res = validate_depot_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_depot(id, res)
      end
      instance = depot(id)
      success_response("Updated depot #{instance.depot_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_depot(id)
      name = depot(id).depot_code
      repo.transaction do
        repo.delete_depot(id)
      end
      success_response("Deleted depot #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Depot.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= DepotRepo.new
    end

    def depot(id)
      repo.find_depot_flat(id)
    end

    def validate_depot_params(params)
      DepotSchema.call(params)
    end
  end
end
