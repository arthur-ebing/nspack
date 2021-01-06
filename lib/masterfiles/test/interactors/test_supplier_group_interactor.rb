# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestSupplierGroupInteractor < MiniTestWithHooks
    include SupplierFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::SupplierRepo)
    end

    def test_supplier_group
      MasterfilesApp::SupplierRepo.any_instance.stubs(:find_supplier_group).returns(fake_supplier_group)
      entity = interactor.send(:supplier_group, 1)
      assert entity.is_a?(SupplierGroup)
    end

    def test_create_supplier_group
      attrs = fake_supplier_group.to_h.reject { |k, _| k == :id }
      res = interactor.create_supplier_group(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(SupplierGroup, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_supplier_group_fail
      attrs = fake_supplier_group(supplier_group_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_supplier_group(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:supplier_group_code]
    end

    def test_update_supplier_group
      id = create_supplier_group
      attrs = interactor.send(:repo).find_hash(:supplier_groups, id).reject { |k, _| k == :id }
      value = attrs[:supplier_group_code]
      attrs[:supplier_group_code] = 'a_change'
      res = interactor.update_supplier_group(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(SupplierGroup, res.instance)
      assert_equal 'a_change', res.instance.supplier_group_code
      refute_equal value, res.instance.supplier_group_code
    end

    def test_update_supplier_group_fail
      id = create_supplier_group
      attrs = interactor.send(:repo).find_hash(:supplier_groups, id).reject { |k, _| %i[id supplier_group_code].include?(k) }
      res = interactor.update_supplier_group(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:supplier_group_code]
    end

    def test_delete_supplier_group
      id = create_supplier_group
      assert_count_changed(:supplier_groups, -1) do
        res = interactor.delete_supplier_group(id)
        assert res.success, res.message
      end
    end

    private

    def supplier_group_attrs
      {
        id: 1,
        supplier_group_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
    end

    def fake_supplier_group(overrides = {})
      SupplierGroup.new(supplier_group_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= SupplierGroupInteractor.new(current_user, {}, {}, {})
    end
  end
end
