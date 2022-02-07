# frozen_string_literal: true

module MasterfilesApp
  class MrlRequirementInteractor < BaseInteractor
    def create_mrl_requirement(params)
      res = validate_mrl_requirement_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_mrl_requirement(res)
        log_status(:mrl_requirements, id, 'CREATED')
        log_transaction
      end
      instance = mrl_requirement(id)
      success_response("Created mrl requirement #{instance.id}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { id: ['This mrl requirement already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_mrl_requirement(id, params)
      res = validate_mrl_requirement_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_mrl_requirement(id, res)
        log_transaction
      end
      instance = mrl_requirement(id)
      success_response("Updated mrl requirement #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_mrl_requirement(id) # rubocop:disable Metrics/AbcSize
      name = mrl_requirement(id).id
      repo.transaction do
        repo.delete_mrl_requirement(id)
        log_status(:mrl_requirements, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted mrl requirement #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete mrl requirement. It is still referenced#{e.message.partition('referenced').last}")
    end

    # def complete_a_mrl_requirement(id, params)
    #   res = complete_a_record(:mrl_requirements, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, mrl_requirement(id))
    #   else
    #     failed_response(res.message, mrl_requirement(id))
    #   end
    # end

    # def reopen_a_mrl_requirement(id, params)
    #   res = reopen_a_record(:mrl_requirements, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, mrl_requirement(id))
    #   else
    #     failed_response(res.message, mrl_requirement(id))
    #   end
    # end

    # def approve_or_reject_a_mrl_requirement(id, params)
    #   res = if params[:approve_action] == 'a'
    #           approve_a_record(:mrl_requirements, id, params.merge(enqueue_job: false))
    #         else
    #           reject_a_record(:mrl_requirements, id, params.merge(enqueue_job: false))
    #         end
    #   if res.success
    #     success_response(res.message, mrl_requirement(id))
    #   else
    #     failed_response(res.message, mrl_requirement(id))
    #   end
    # end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::MrlRequirement.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= MrlRequirementRepo.new
    end

    def mrl_requirement(id)
      repo.find_mrl_requirement(id)
    end

    def validate_mrl_requirement_params(params)
      # MrlRequirementSchema.call(params)
      contract = MrlRequirementContract.new
      contract.call(params)
    end
  end
end
