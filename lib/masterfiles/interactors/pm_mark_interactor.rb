# frozen_string_literal: true

module MasterfilesApp
  class PmMarkInteractor < BaseInteractor
    def create_pm_mark(params) # rubocop:disable Metrics/AbcSize
      res = validate_pm_mark_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_pm_mark(res)
        log_status(:pm_marks, id, 'CREATED')
        log_transaction
      end
      instance = pm_mark(id)
      success_response("Created PKG Mark #{instance.description}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { mark_id: ['This PKG Mark already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_pm_mark(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_pm_mark_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_pm_mark(id, res)
        log_transaction
      end
      instance = pm_mark(id)
      success_response("Updated PKG Mark #{instance.description}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { mark_id: ['This PKG Mark already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_pm_mark(id) # rubocop:disable Metrics/AbcSize
      name = pm_mark(id).description
      repo.transaction do
        repo.delete_pm_mark(id)
        log_status(:pm_marks, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted PKG Mark #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete PKG Mark. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PmMark.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= BomRepo.new
    end

    def pm_mark(id)
      repo.find_pm_mark(id)
    end

    def validate_pm_mark_params(params)
      params[:packaging_marks] = []
      repo.list_pm_composition_levels.each {  |_, v| params[:packaging_marks] << params[v.to_sym] }

      PmMarkSchema.call(params)
    end
  end
end
