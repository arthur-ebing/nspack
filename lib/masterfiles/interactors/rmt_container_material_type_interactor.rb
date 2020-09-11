# frozen_string_literal: true

module MasterfilesApp
  class RmtContainerMaterialTypeInteractor < BaseInteractor
    def repo
      @repo ||= RmtContainerMaterialTypeRepo.new
    end

    def rmt_container_material_type(id)
      repo.find_rmt_container_material_type(id)
    end

    def validate_rmt_container_material_type_params(params)
      RmtContainerMaterialTypeSchema.call(params)
    end

    def create_rmt_container_material_type(params) # rubocop:disable Metrics/AbcSize
      res = validate_rmt_container_material_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_rmt_container_material_type(res)
        log_status('rmt_container_material_types', id, 'CREATED')
        log_transaction
      end
      instance = rmt_container_material_type(id)
      success_response("Created rmt container material type #{instance.container_material_type_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { container_material_type_code: ['This rmt container material type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_rmt_container_material_type(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_rmt_container_material_type_params(params)
      return validation_failed_response(res) if res.failure?

      attrs = res.to_h
      party_role_ids = attrs.delete(:party_role_ids)
      assign_container_owners_response = assign_container_owners(id, party_role_ids)
      if assign_container_owners_response.success
        repo.transaction do
          repo.update_rmt_container_material_type(id, res)
          log_transaction
        end
        instance = rmt_container_material_type(id)
        success_response("Updated rmt container material type #{instance.container_material_type_code}",
                         instance)
      else
        validation_failed_response(OpenStruct.new(messages: { roles: ['Could no assign party role'] }))
      end
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assign_container_owners(id, party_role_ids)
      # return validation_failed_response(OpenStruct.new(messages: { roles: ['You did not choose a party role'] })) if party_role_ids.empty?
      party_role_ids ||= []

      repo.transaction do
        create_rmt_material_container_owners(id, party_role_ids)
      end
      success_response('Party Roles assigned successfully')
    end

    def create_rmt_material_container_owners(id, party_role_ids)
      current_rmt_material_container_owners = repo.get_current_rmt_material_container_owners(id)
      current_party_role_ids = current_rmt_material_container_owners.select_map(:rmt_material_owner_party_role_id)
      removed_party_role_ids = current_party_role_ids - party_role_ids
      new_party_role_ids = party_role_ids - current_party_role_ids

      repo.delete_rmt_material_container_owners(current_rmt_material_container_owners, removed_party_role_ids)
      new_party_role_ids.each do |pr_id|
        repo.create_rmt_material_container_owner(id, pr_id)
      end
    end

    def delete_rmt_container_material_type(id)
      name = rmt_container_material_type(id).container_material_type_code
      repo.transaction do
        repo.delete_rmt_container_material_type(id)
        log_status('rmt_container_material_types', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted rmt container material type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    # def complete_a_rmt_container_material_type(id, params)
    #   res = complete_a_record(:rmt_container_material_types, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, rmt_container_material_type(id))
    #   else
    #     failed_response(res.message, rmt_container_material_type(id))
    #   end
    # end

    # def reopen_a_rmt_container_material_type(id, params)
    #   res = reopen_a_record(:rmt_container_material_types, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, rmt_container_material_type(id))
    #   else
    #     failed_response(res.message, rmt_container_material_type(id))
    #   end
    # end

    # def approve_or_reject_a_rmt_container_material_type(id, params)
    #   res = if params[:approve_action] == 'a'
    #           approve_a_record(:rmt_container_material_types, id, params.merge(enqueue_job: false))
    #         else
    #           reject_a_record(:rmt_container_material_types, id, params.merge(enqueue_job: false))
    #         end
    #   if res.success
    #     success_response(res.message, rmt_container_material_type(id))
    #   else
    #     failed_response(res.message, rmt_container_material_type(id))
    #   end
    # end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::RmtContainerMaterialType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end
  end
end
