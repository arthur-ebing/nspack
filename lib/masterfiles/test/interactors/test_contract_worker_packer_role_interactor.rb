# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestContractWorkerPackerRoleInteractor < MiniTestWithHooks
    include HRFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::HumanResourcesRepo)
    end

    def test_contract_worker_packer_role
      MasterfilesApp::HumanResourcesRepo.any_instance.stubs(:find_contract_worker_packer_role).returns(fake_contract_worker_packer_role)
      entity = interactor.send(:contract_worker_packer_role, 1)
      assert entity.is_a?(ContractWorkerPackerRole)
    end

    def test_create_contract_worker_packer_role
      attrs = fake_contract_worker_packer_role.to_h.reject { |k, _| k == :id }
      res = interactor.create_contract_worker_packer_role(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(ContractWorkerPackerRole, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_contract_worker_packer_role_fail
      attrs = fake_contract_worker_packer_role(packer_role: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_contract_worker_packer_role(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:packer_role]
    end

    def test_update_contract_worker_packer_role
      id = create_contract_worker_packer_role
      attrs = interactor.send(:repo).find_hash(:contract_worker_packer_roles, id).reject { |k, _| k == :id }
      value = attrs[:packer_role]
      attrs[:packer_role] = 'a_change'
      res = interactor.update_contract_worker_packer_role(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(ContractWorkerPackerRole, res.instance)
      assert_equal 'a_change', res.instance.packer_role
      refute_equal value, res.instance.packer_role
    end

    def test_update_contract_worker_packer_role_fail
      id = create_contract_worker_packer_role
      attrs = interactor.send(:repo).find_hash(:contract_worker_packer_roles, id).reject { |k, _| %i[id packer_role].include?(k) }
      res = interactor.update_contract_worker_packer_role(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:packer_role]
    end

    def test_delete_contract_worker_packer_role
      id = create_contract_worker_packer_role
      assert_count_changed(:contract_worker_packer_roles, -1) do
        res = interactor.delete_contract_worker_packer_role(id)
        assert res.success, res.message
      end
    end

    private

    def contract_worker_packer_role_attrs
      {
        id: 1,
        packer_role: Faker::Lorem.unique.word,
        default_role: false,
        part_of_group_incentive_target: false,
        active: true
      }
    end

    def fake_contract_worker_packer_role(overrides = {})
      ContractWorkerPackerRole.new(contract_worker_packer_role_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= ContractWorkerPackerRoleInteractor.new(current_user, {}, {}, {})
    end
  end
end
