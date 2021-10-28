# frozen_string_literal: true

module RawMaterialsApp
  class LocationInteractor < BaseInteractor
    def apply_status(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_location_status_params(params)
      return validation_failed_response(res) if res.failure?

      instance = location(id)
      return failed_response('Nothing changed - please choose a different status') if instance.current_status == res[:status]

      ids = 0
      repo.transaction do
        ids = repo.bin_ids_for_location(id)
        log_status(:locations, id, res[:status])
        log_multiple_statuses(:rmt_bins, ids, res[:status])
        log_transaction
      end
      instance = location(id)
      success_response("Set location #{instance.location_long_code} and #{ids.length} bin#{ids.length == 1 ? '' : 's'} to #{res[:status]}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Location.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= LocationRepo.new
    end

    def location(id)
      repo.find_location(id)
    end

    def validate_location_status_params(params)
      LocationStatusSchema.call(params)
    end
  end
end
