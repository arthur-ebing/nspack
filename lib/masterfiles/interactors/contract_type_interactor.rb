# frozen_string_literal: true

module MasterfilesApp
  class ContractTypeInteractor < BaseInteractor
    def create_contract_type(params) # rubocop:disable Metrics/AbcSize
      res = validate_contract_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_contract_type(res)
        log_status(:contract_types, id, 'CREATED')
        log_transaction
      end
      instance = contract_type(id)
      success_response("Created contract type #{instance.contract_type_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { contract_type_code: ['This contract type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_contract_type(id, params)
      res = validate_contract_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_contract_type(id, res)
        log_transaction
      end
      instance = contract_type(id)
      success_response("Updated contract type #{instance.contract_type_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_contract_type(id)
      name = contract_type(id).contract_type_code
      repo.transaction do
        repo.delete_contract_type(id)
        log_status(:contract_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted contract type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::ContractType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= HumanResourcesRepo.new
    end

    def contract_type(id)
      repo.find_contract_type(id)
    end

    def validate_contract_type_params(params)
      ContractTypeSchema.call(params)
    end
  end
end
