# frozen_string_literal: true

module MasterfilesApp
  class PmBomsProductInteractor < BaseInteractor
    def create_pm_boms_product(params) # rubocop:disable Metrics/AbcSize
      res = validate_pm_boms_product_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_pm_boms_product(res)
        log_status('pm_boms_products', id, 'CREATED')
        log_transaction
      end
      instance = pm_boms_product(id)
      success_response("Created pm boms product #{instance.id}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { uom_id: ['This pm boms product already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_pm_boms_product(id, params)
      res = validate_pm_boms_product_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_pm_boms_product(id, res)
        log_transaction
      end
      instance = pm_boms_product(id)
      success_response("Updated pm boms product #{instance.id}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_pm_boms_product(id)
      name = pm_boms_product(id).id
      repo.transaction do
        repo.delete_pm_boms_product(id)
        log_status('pm_boms_products', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted pm boms product #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PmBomsProduct.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= BomsRepo.new
    end

    def pm_boms_product(id)
      repo.find_pm_boms_product(id)
    end

    def validate_pm_boms_product_params(params)
      PmBomsProductSchema.call(params)
    end
  end
end
