# frozen_string_literal: true

module MasterfilesApp
  class ChemicalInteractor < BaseInteractor
    def create_chemical(params)
      res = validate_chemical_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_chemical(res)
        log_status(:chemicals, id, 'CREATED')
        log_transaction
      end
      instance = chemical(id)
      success_response("Created chemical #{instance.chemical_name}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { chemical_name: ['This chemical already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_chemical(id, params)
      res = validate_chemical_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_chemical(id, res)
        log_transaction
      end
      instance = chemical(id)
      success_response("Updated chemical #{instance.chemical_name}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_chemical(id) # rubocop:disable Metrics/AbcSize
      name = chemical(id).chemical_name
      repo.transaction do
        repo.delete_chemical(id)
        log_status(:chemicals, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted chemical #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete chemical. It is still referenced#{e.message.partition('referenced').last}")
    end

    # def complete_a_chemical(id, params)
    #   res = complete_a_record(:chemicals, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, chemical(id))
    #   else
    #     failed_response(res.message, chemical(id))
    #   end
    # end

    # def reopen_a_chemical(id, params)
    #   res = reopen_a_record(:chemicals, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, chemical(id))
    #   else
    #     failed_response(res.message, chemical(id))
    #   end
    # end

    # def approve_or_reject_a_chemical(id, params)
    #   res = if params[:approve_action] == 'a'
    #           approve_a_record(:chemicals, id, params.merge(enqueue_job: false))
    #         else
    #           reject_a_record(:chemicals, id, params.merge(enqueue_job: false))
    #         end
    #   if res.success
    #     success_response(res.message, chemical(id))
    #   else
    #     failed_response(res.message, chemical(id))
    #   end
    # end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Chemical.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= ChemicalRepo.new
    end

    def chemical(id)
      repo.find_chemical(id)
    end

    def validate_chemical_params(params)
      ChemicalSchema.call(params)
    end
  end
end
