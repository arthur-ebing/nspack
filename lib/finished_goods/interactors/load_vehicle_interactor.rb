# frozen_string_literal: true

module FinishedGoodsApp
  class LoadVehicleInteractor < BaseInteractor
    def create_load_vehicle(params) # rubocop:disable Metrics/AbcSize
      res = validate_load_vehicle_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      load_id = res.to_h[:load_id]
      pallet_ids = repo.select_values(:pallets, :id, load_id: load_id)

      repo.transaction do
        id = repo.create_load_vehicle(res)
        log_status(:load_vehicles, id, 'CREATED')
        log_status(:loads, load_id, 'TRUCK ARRIVED')
        log_multiple_statuses(:pallets, pallet_ids, 'TRUCK ARRIVED') unless pallet_ids.empty?
        log_transaction
      end
      instance = load_vehicle(id)
      success_response("Created load vehicle #{instance.vehicle_number}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { vehicle_number: ['This load vehicle already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_load_vehicle(id, params)
      res = validate_load_vehicle_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_load_vehicle(id, res)
        log_transaction
      end
      instance = load_vehicle(id)
      success_response("Updated load vehicle #{instance.vehicle_number}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_load_vehicle(id)
      name = load_vehicle(id).vehicle_number
      repo.transaction do
        repo.delete_load_vehicle(id)
        log_status(:load_vehicles, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted load vehicle #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::LoadVehicle.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= LoadVehicleRepo.new
    end

    def load_repo
      @load_repo ||= LoadRepo.new
    end

    def load_vehicle(id)
      repo.find_load_vehicle(id)
    end

    def validate_load_vehicle_params(params)
      LoadVehicleSchema.call(params)
    end
  end
end
