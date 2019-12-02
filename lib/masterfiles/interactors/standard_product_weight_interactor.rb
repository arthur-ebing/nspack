# frozen_string_literal: true

module MasterfilesApp
  class StandardProductWeightInteractor < BaseInteractor
    def create_standard_product_weight(params) # rubocop:disable Metrics/AbcSize
      res = validate_standard_product_weight_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_standard_product_weight(res)
        log_status(:standard_product_weights, id, 'CREATED')
        log_transaction
      end
      instance = standard_product_weight(id)
      success_response("Created standard product weight #{instance.id}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { id: ['This standard product weight already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_standard_product_weight(id, params)
      res = validate_standard_product_weight_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_standard_product_weight(id, res)
        log_transaction
      end
      instance = standard_product_weight(id)
      success_response("Updated standard product weight #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_standard_product_weight(id)
      name = standard_product_weight(id).id
      repo.transaction do
        repo.delete_standard_product_weight(id)
        log_status(:standard_product_weights, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted standard product weight #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::StandardProductWeight.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FruitSizeRepo.new
    end

    def standard_product_weight(id)
      repo.find_standard_product_weight_flat(id)
    end

    def validate_standard_product_weight_params(params)
      StandardProductWeightSchema.call(params)
    end
  end
end
