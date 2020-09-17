# frozen_string_literal: true

module MasterfilesApp
  class ProductionRegionInteractor < BaseInteractor
    def repo
      @repo ||= FarmRepo.new
    end

    def production_region(id)
      repo.find_production_region(id)
    end

    def validate_production_region_params(params)
      ProductionRegionSchema.call(params)
    end

    def create_production_region(params) # rubocop:disable Metrics/AbcSize
      res = validate_production_region_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_production_region(res)
        log_status('production_regions', id, 'CREATED')
        log_transaction
      end
      instance = production_region(id)
      success_response("Created production region #{instance.production_region_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { production_region_code: ['This production region already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_production_region(id, params)
      res = validate_production_region_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_production_region(id, res)
        log_transaction
      end
      instance = production_region(id)
      success_response("Updated production region #{instance.production_region_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_production_region(id)
      name = production_region(id).production_region_code
      repo.transaction do
        repo.delete_production_region(id)
        log_status('production_regions', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted production region #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::ProductionRegion.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end
  end
end
