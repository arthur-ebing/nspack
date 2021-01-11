# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestSupplierInteractor < MiniTestWithHooks
    include SupplierFactory
    include PartyFactory
    include FarmFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::SupplierRepo)
    end

    def test_supplier
      MasterfilesApp::SupplierRepo.any_instance.stubs(:find_supplier).returns(fake_supplier)
      entity = interactor.send(:supplier, 1)
      assert entity.is_a?(Supplier)
    end

    def test_create_supplier
      attrs = fake_supplier.to_h.reject { |k, _| k == :id }
      res = interactor.create_supplier(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Supplier, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_supplier_fail
      attrs = fake_supplier(id: nil).to_h.reject { |k, _| %i[id farm_ids].include?(k) }
      res = interactor.create_supplier(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['is missing'], res.errors[:farm_ids]
    end

    def test_update_supplier
      id = create_supplier
      attrs = interactor.send(:repo).find_hash(:suppliers, id).reject { |k, _| k == :id }
      value = attrs[:farm_ids]
      attrs[:farm_ids] = [4, 5, 6]
      res = interactor.update_supplier(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Supplier, res.instance)
      assert_equal [4, 5, 6], res.instance.farm_ids
      refute_equal value, res.instance.farm_ids
    end

    def test_update_supplier_fail
      id = create_supplier
      attrs = interactor.send(:repo).find_hash(:suppliers, id).reject { |k, _| %i[id supplier_party_role_id].include?(k) }
      res = interactor.update_supplier(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:supplier_party_role_id]
    end

    def test_delete_supplier
      id = create_supplier
      assert_count_changed(:suppliers, -1) do
        res = interactor.delete_supplier(id)
        assert res.success, res.message
      end
    end

    private

    def supplier_attrs
      party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_SUPPLIER)
      supplier_group_id = create_supplier_group
      farm_id = create_farm
      {
        id: 1,
        supplier_party_role_id: party_role_id.to_s,
        supplier: Faker::Lorem.unique.word,
        supplier_group_ids: [supplier_group_id],
        supplier_group_codes: %i[A B C],
        farm_ids: [farm_id],
        farm_codes: %i[A B C],
        active: true
      }
    end

    def fake_supplier(overrides = {})
      Supplier.new(supplier_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= SupplierInteractor.new(current_user, {}, {}, {})
    end
  end
end
