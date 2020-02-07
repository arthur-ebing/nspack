# frozen_string_literal: true

module MasterfilesApp
  class InspectorInteractor < BaseInteractor
    def create_inspector(params) # rubocop:disable Metrics/AbcSize
      res = validate_inspector_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_inspector(res)
        log_status(:inspectors, id, 'CREATED')
        log_transaction
      end
      instance = inspector(id)
      success_response("Created inspector #{instance.inspector_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { first_name: ['This person or inspector code already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_inspector(id, params)
      res = validate_inspector_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_inspector(id, res)
        log_transaction
      end
      instance = inspector(id)
      success_response("Updated inspector #{instance.inspector_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_inspector(id)
      name = inspector(id).inspector_code
      repo.transaction do
        repo.delete_inspector(id)
        log_status(:inspectors, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted inspector #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Inspector.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= InspectorRepo.new
    end

    def inspector(id)
      repo.find_inspector_flat(id)
    end

    def validate_inspector_params(params)
      InspectorFlatSchema.call(params)
    end
  end
end
