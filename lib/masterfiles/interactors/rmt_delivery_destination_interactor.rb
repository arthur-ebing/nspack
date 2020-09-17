# frozen_string_literal: true

module MasterfilesApp
  class RmtDeliveryDestinationInteractor < BaseInteractor
    def repo
      @repo ||= RmtDeliveryDestinationRepo.new
    end

    def rmt_delivery_destination(id)
      repo.find_rmt_delivery_destination(id)
    end

    def validate_rmt_delivery_destination_params(params)
      RmtDeliveryDestinationSchema.call(params)
    end

    def create_rmt_delivery_destination(params) # rubocop:disable Metrics/AbcSize
      res = validate_rmt_delivery_destination_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_rmt_delivery_destination(res)
        log_status('rmt_delivery_destinations', id, 'CREATED')
        log_transaction
      end
      instance = rmt_delivery_destination(id)
      success_response("Created rmt delivery destination #{instance.delivery_destination_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { delivery_destination_code: ['This rmt delivery destination already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_rmt_delivery_destination(id, params)
      res = validate_rmt_delivery_destination_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_rmt_delivery_destination(id, res)
        log_transaction
      end
      instance = rmt_delivery_destination(id)
      success_response("Updated rmt delivery destination #{instance.delivery_destination_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_rmt_delivery_destination(id)
      name = rmt_delivery_destination(id).delivery_destination_code
      repo.transaction do
        repo.delete_rmt_delivery_destination(id)
        log_status('rmt_delivery_destinations', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted rmt delivery destination #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::RmtDeliveryDestination.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end
  end
end
