# frozen_string_literal: true

module MasterfilesApp
  class PmProductInteractor < BaseInteractor
    def create_pm_product(params) # rubocop:disable Metrics/AbcSize
      res = validate_pm_product_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_pm_product(res)
        log_status(:pm_products, id, 'CREATED')
        log_transaction
      end
      instance = pm_product(id)
      success_response("Created PKG Product #{instance.product_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      failed_response('This PKG Product already exists')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_pm_product(id, params)
      res = validate_pm_product_params(params, id)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_pm_product(id, res)
        log_transaction
      end
      instance = pm_product(id)
      success_response("Updated PKG Product #{instance.product_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_pm_product(id) # rubocop:disable Metrics/AbcSize
      name = pm_product(id).product_code
      repo.transaction do
        repo.delete_pm_product(id)
        log_status(:pm_products, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted PKG Product #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete PKG Product. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PmProduct.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def pm_product(id)
      repo.find_pm_product(id)
    end

    def pm_subtype(id)
      repo.find_pm_subtype(id)
    end

    private

    def repo
      @repo ||= BomRepo.new
    end

    def validate_pm_product_params(params, id = nil)
      ValidateCompileProductCode.call(params, id)
    end
  end
end
