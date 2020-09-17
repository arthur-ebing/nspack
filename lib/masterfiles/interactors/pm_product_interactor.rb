# frozen_string_literal: true

module MasterfilesApp
  class PmProductInteractor < BaseInteractor
    def create_pm_product(params) # rubocop:disable Metrics/AbcSize
      res = validate_pm_product_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_pm_product(res)
        log_status('pm_products', id, 'CREATED')
        log_transaction
      end
      instance = pm_product(id)
      success_response("Created pm product #{instance.product_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { product_code: ['This pm product already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_pm_product(id, params)
      res = validate_pm_product_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_pm_product(id, res)
        log_transaction
      end
      instance = pm_product(id)
      success_response("Updated pm product #{instance.product_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_pm_product(id)
      name = pm_product(id).product_code
      repo.transaction do
        repo.delete_pm_product(id)
        log_status('pm_products', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted pm product #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PmProduct.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= BomsRepo.new
    end

    def pm_product(id)
      repo.find_pm_product(id)
    end

    def validate_pm_product_params(params)
      PmProductSchema.call(params)
    end
  end
end
