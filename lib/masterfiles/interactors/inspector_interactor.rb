# frozen_string_literal: true

module MasterfilesApp
  class InspectorInteractor < BaseInteractor
    def create_inspector(params) # rubocop:disable Metrics/AbcSize
      res = CreateInspectorSchema.call(params)
      return validation_failed_response(res) if res.failure?

      params = res.to_h
      id = nil
      repo.transaction do
        res = CreatePartyRole.call(AppConst::ROLE_INSPECTOR, params, @user)
        raise Crossbeams::ServiceError unless res.success

        params[:inspector_party_role_id] = res.instance.party_role_id
        res = InspectorSchema.call(params)
        raise Crossbeams::ServiceError if res.failure?

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
    rescue Crossbeams::ServiceError
      res
    end

    def update_inspector(id, params) # rubocop:disable Metrics/AbcSize
      res = InspectorSchema.call(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_inspector(id, res)
        log_transaction
      end
      instance = inspector(id)
      success_response("Updated inspector #{instance.inspector_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { inspector_code: ['This inspector code already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_inspector(id)
      instance = inspector(id)
      repo.transaction do
        repo.delete_inspector(id)
        PartyRepo.new.delete_party_role(instance.inspector_party_role_id)
        log_status(:inspectors, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted inspector #{instance.inspector_code}")
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
      repo.find_inspector(id)
    end
  end
end
