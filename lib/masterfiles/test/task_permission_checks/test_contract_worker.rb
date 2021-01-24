# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestContractWorkerPermission < Minitest::Test
    include Crossbeams::Responses
    include HRFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        employment_type_id: 1,
        contract_type_id: 1,
        wage_level_id: 1,
        first_name: Faker::Lorem.unique.word,
        surname: 'ABC',
        title: 'ABC',
        email: 'ABC',
        contact_number: 'ABC',
        personnel_number: 'ABC',
        start_date: '2010-01-01',
        end_date: '2010-01-01',
        personnel_identifier_id: 1,
        shift_type_id: 1,
        packer_role_id: 1,
        shift_type_code: 'ABC',
        employment_type_code: 'ABC',
        contract_type_code: 'ABC',
        contract_worker_name: 'ABC',
        packer_role: 'ABC',
        wage_level: 1.2,
        active: true
      }
      MasterfilesApp::ContractWorker.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::ContractWorker.call(:create)
      assert res.success, 'Should always be able to create a contract_worker'
    end

    def test_edit
      MasterfilesApp::HumanResourcesRepo.any_instance.stubs(:find_contract_worker).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::ContractWorker.call(:edit, 1)
      assert res.success, 'Should be able to edit a contract_worker'

      # MasterfilesApp::HumanResourcesRepo.any_instance.stubs(:find_contract_worker).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::ContractWorker.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed contract_worker'
    end

    def test_delete
      MasterfilesApp::HumanResourcesRepo.any_instance.stubs(:find_contract_worker).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::ContractWorker.call(:delete, 1)
      assert res.success, 'Should be able to delete a contract_worker'

      # MasterfilesApp::HumanResourcesRepo.any_instance.stubs(:find_contract_worker).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::ContractWorker.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed contract_worker'
    end

    # def test_complete
    #   MasterfilesApp::HumanResourcesRepo.any_instance.stubs(:find_contract_worker).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::ContractWorker.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a contract_worker'

    #   MasterfilesApp::HumanResourcesRepo.any_instance.stubs(:find_contract_worker).returns(entity(completed: true))
    #   res = MasterfilesApp::TaskPermissionCheck::ContractWorker.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed contract_worker'
    # end

    # def test_approve
    #   MasterfilesApp::HumanResourcesRepo.any_instance.stubs(:find_contract_worker).returns(entity(completed: true, approved: false))
    #   res = MasterfilesApp::TaskPermissionCheck::ContractWorker.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed contract_worker'

    #   MasterfilesApp::HumanResourcesRepo.any_instance.stubs(:find_contract_worker).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::ContractWorker.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed contract_worker'

    #   MasterfilesApp::HumanResourcesRepo.any_instance.stubs(:find_contract_worker).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::ContractWorker.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved contract_worker'
    # end

    # def test_reopen
    #   MasterfilesApp::HumanResourcesRepo.any_instance.stubs(:find_contract_worker).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::ContractWorker.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a contract_worker that has not been approved'

    #   MasterfilesApp::HumanResourcesRepo.any_instance.stubs(:find_contract_worker).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::ContractWorker.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved contract_worker'
    # end
  end
end
