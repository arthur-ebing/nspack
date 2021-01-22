# frozen_string_literal: true

module MasterfilesApp
  class PmCompositionLevelInteractor < BaseInteractor
    def create_pm_composition_level(params)  # rubocop:disable Metrics/AbcSize
      res = validate_pm_composition_level_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_pm_composition_level(res)
        log_status(:pm_composition_levels, id, 'CREATED')
        log_transaction
      end
      instance = pm_composition_level(id)
      success_response("Created pm composition level #{instance.description}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { description: ['This PM Composition level already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_pm_composition_level(id, params)
      res = validate_pm_composition_level_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_pm_composition_level(id, res)
        log_transaction
      end
      instance = pm_composition_level(id)
      success_response("Updated pm composition level #{instance.description}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_pm_composition_level(id)  # rubocop:disable Metrics/AbcSize
      name = pm_composition_level(id).description
      repo.transaction do
        repo.delete_pm_composition_level(id)
        log_status(:pm_composition_levels, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted pm composition level #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete pm composition level. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PmCompositionLevel.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def reorder_composition_levels(params)
      repo.reorder_composition_levels(params)
      success_response('Re-ordered composition levels')
    end

    private

    def repo
      @repo ||= BomRepo.new
    end

    def pm_composition_level(id)
      repo.find_pm_composition_level(id)
    end

    def validate_pm_composition_level_params(params)
      PmCompositionLevelSchema.call(params)
    end
  end
end
