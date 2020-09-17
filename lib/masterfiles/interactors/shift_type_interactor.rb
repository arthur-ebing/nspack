# frozen_string_literal: true

module MasterfilesApp
  class ShiftTypeInteractor < BaseInteractor
    def create_shift_type(params) # rubocop:disable Metrics/AbcSize
      res = validate_shift_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_shift_type(res)
        log_status(:shift_types, id, 'CREATED')
        log_transaction
      end
      instance = shift_type(id)
      success_response("Created shift type #{instance.shift_type_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { ph_plant_resource_id: ['This shift type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_shift_type(id) # rubocop:disable Metrics/AbcSize
      name = shift_type(id).shift_type_code
      repo.transaction do
        repo.delete_shift_type(id)
        log_status(:shift_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted shift type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete shift type. It is still referenced#{e.message.partition('referenced').last}")
    end

    def swap_employees(params) # rubocop:disable Metrics/AbcSize
      res = ShiftTypeIdsSchema.call(params)
      return validation_failed_response(res) if res.failure?

      from_st = shift_type(params[:from_shift_type_id])
      to_st = shift_type(params[:to_shift_type_id])
      repo.transaction do
        repo.swap_employees(res)
        log_status(:shift_types, params[:from_shift_type_id], 'SWAP EMPLOYEES')
        log_status(:shift_types, params[:to_shift_type_id], 'SWAP EMPLOYEES')
        log_transaction
      end
      success_response("Swapped Employees from #{from_st.shift_type_code} with #{to_st.shift_type_code}")
    end

    def move_employees(params) # rubocop:disable Metrics/AbcSize
      res = ShiftTypeIdsSchema.call(params)
      return validation_failed_response(res) if res.failure?

      from_st = shift_type(params[:from_shift_type_id])
      to_st = shift_type(params[:to_shift_type_id])
      repo.transaction do
        repo.move_employees(res)
        log_status(:shift_types, params[:from_shift_type_id], 'MOVED EMPLOYEES')
        log_status(:shift_types, params[:to_shift_type_id], 'EMPLOYEES MOVED')
        log_transaction
      end
      success_response("Moved Employees from #{from_st.shift_type_code} with #{to_st.shift_type_code}")
    end

    def link_employees(shift_type_id, contract_worker_ids)
      code = shift_type(shift_type_id)&.shift_type_code
      repo.transaction do
        repo.link_employees(shift_type_id, contract_worker_ids)
      end
      success_response("Contract Workers assigned to #{code}")
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

    def validate_shift_type_params(params)
      # ShiftTypeSchema.call(params)
      contract = ShiftTypeContract.new
      contract.call(params)
    end
  end
end
