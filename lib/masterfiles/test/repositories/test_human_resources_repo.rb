# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestHumanResourcesRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_contract_workers
      assert_respond_to repo, :for_select_contract_worker_packer_roles
    end

    def test_crud_calls
      test_crud_calls_for :contract_workers, name: :contract_worker, wrapper: ContractWorker
      test_crud_calls_for :contract_worker_packer_roles, name: :contract_worker_packer_role, wrapper: ContractWorkerPackerRole
    end

    private

    def repo
      HumanResourcesRepo.new
    end
  end
end
