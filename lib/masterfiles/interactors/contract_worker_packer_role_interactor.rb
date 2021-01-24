# frozen_string_literal: true

module MasterfilesApp
  class ContractWorkerPackerRoleInteractor < BaseInteractor
    def create_contract_worker_packer_role(params) # rubocop:disable Metrics/AbcSize
      res = validate_contract_worker_packer_role_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_contract_worker_packer_role(res)
        log_transaction
      end
      instance = contract_worker_packer_role(id)
      success_response("Created contract worker packer role #{instance.packer_role}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { packer_role: ['This contract worker packer role already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_contract_worker_packer_role(id, params)
      res = validate_contract_worker_packer_role_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_contract_worker_packer_role(id, res)
        log_transaction
      end
      instance = contract_worker_packer_role(id)
      success_response("Updated contract worker packer role #{instance.packer_role}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_contract_worker_packer_role(id) # rubocop:disable Metrics/AbcSize
      name = contract_worker_packer_role(id).packer_role
      repo.transaction do
        repo.delete_contract_worker_packer_role(id)
        log_transaction
      end
      success_response("Deleted contract worker packer role #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete contract worker packer role. It is still referenced#{e.message.partition('referenced').last}")
    end

    private

    def repo
      @repo ||= HumanResourcesRepo.new
    end

    def contract_worker_packer_role(id)
      repo.find_contract_worker_packer_role(id)
    end

    def validate_contract_worker_packer_role_params(params)
      ContractWorkerPackerRoleSchema.call(params)
    end
  end
end
