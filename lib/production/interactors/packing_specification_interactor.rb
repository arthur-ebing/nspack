# frozen_string_literal: true

module ProductionApp
  class PackingSpecificationInteractor < BaseInteractor
    def create_packing_specification(params) # rubocop:disable Metrics/AbcSize
      res = validate_packing_specification_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_packing_specification(res)
        log_status(:packing_specifications, id, 'CREATED')
        log_transaction
      end
      instance = packing_specification(id)
      success_response("Created packing specification #{instance.packing_specification_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { packing_specification_code: ['This packing specification already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_packing_specification(id, params)
      res = validate_packing_specification_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_packing_specification(id, res)
        log_transaction
      end
      instance = packing_specification(id)
      success_response("Updated packing specification #{instance.packing_specification_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_packing_specification(id) # rubocop:disable Metrics/AbcSize
      name = packing_specification(id).packing_specification_code
      repo.transaction do
        repo.delete_packing_specification(id)
        log_status(:packing_specifications, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted packing specification #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete packing specification. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PackingSpecification.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= PackingSpecificationRepo.new
    end

    def packing_specification(id)
      repo.find_packing_specification(id)
    end

    def validate_packing_specification_params(params)
      PackingSpecificationSchema.call(params)
    end
  end
end
