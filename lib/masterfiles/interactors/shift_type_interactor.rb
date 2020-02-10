# frozen_string_literal: true

module MasterfilesApp
  class ShiftTypeInteractor < BaseInteractor
    def create_shift_type(params) # rubocop:disable Metrics/AbcSize
      res = HumanResources::Validator.new.validate_shift_type_params(params)
      return res unless res.success

      id = nil
      repo.transaction do
        id = repo.create_shift_type(res)
        log_status(:shift_types, id, 'CREATED')
        log_transaction
      end
      instance = shift_type(id)
      success_response("Created shift type #{instance.shift_type_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { id: ['This shift type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_shift_type(id)
      name = shift_type(id).id
      repo.transaction do
        repo.delete_shift_type(id)
        log_status(:shift_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted shift type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::ShiftType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def line_plant_resources(ph_pr_id)
      repo.for_select_plant_resources_for_ph_pr_id(ph_pr_id)
    end

    private

    def repo
      @repo ||= HumanResourcesRepo.new
    end

    def shift_type(id)
      repo.find_shift_type(id)
    end
  end
end
