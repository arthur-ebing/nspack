# frozen_string_literal: true

module MasterfilesApp
  class DepotInteractor < BaseInteractor
    def create_depot(params) # rubocop:disable Metrics/AbcSize
      res = validate_depot_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_depot(res)
        repo.create_depot_location(res) if AppConst::CR_RMT.create_depot_location? && res[:bin_depot]
      end
      instance = depot(id)
      success_response("Created depot #{instance.depot_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { depot_code: ['This depot already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_depot(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_depot_params(params)
      return validation_failed_response(res) if res.failure?

      depot_location_id = depot_location_id(id)
      location_attrs = { location_short_code: res[:depot_code],
                         location_long_code: res[:depot_code],
                         location_description: res[:depot_code] }
      repo.transaction do
        repo.update_depot(id, res)
        location_repo.update_location(depot_location_id, location_attrs) if AppConst::CR_RMT.create_depot_location?
      end
      instance = depot(id)
      success_response("Updated depot #{instance.depot_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_depot(id)
      name = depot(id).depot_code
      depot_location_id = depot_location_id(id)
      repo.transaction do
        repo.delete_depot(id)
        location_repo.delete_location(depot_location_id) if AppConst::CR_RMT.create_depot_location?
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

    def location_repo
      @location_repo ||= LocationRepo.new
    end

    def depot(id)
      repo.find_depot_flat(id)
    end

    def validate_depot_params(params)
      DepotSchema.call(params)
    end

    def depot_location_id(depot_id)
      RawMaterialsApp::BinAssetsRepo.new.get_dest_depot_location_id(depot_id)
    end
  end
end
