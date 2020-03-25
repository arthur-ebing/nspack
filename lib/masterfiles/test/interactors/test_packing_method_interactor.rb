# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPackingMethodInteractor < MiniTestWithHooks
    include PackagingFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::PackagingRepo)
    end

    def test_packing_method
      MasterfilesApp::PackagingRepo.any_instance.stubs(:find_packing_method).returns(fake_packing_method)
      entity = interactor.send(:packing_method, 1)
      assert entity.is_a?(PackingMethod)
    end

    def test_create_packing_method
      attrs = fake_packing_method.to_h.reject { |k, _| k == :id }
      res = interactor.create_packing_method(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PackingMethod, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_packing_method_fail
      attrs = fake_packing_method(packing_method_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_packing_method(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:packing_method_code]
    end

    def test_update_packing_method
      id = create_packing_method
      attrs = interactor.send(:repo).find_hash(:packing_methods, id).reject { |k, _| k == :id }
      value = attrs[:packing_method_code]
      attrs[:packing_method_code] = 'a_change'
      res = interactor.update_packing_method(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PackingMethod, res.instance)
      assert_equal 'a_change', res.instance.packing_method_code
      refute_equal value, res.instance.packing_method_code
    end

    def test_update_packing_method_fail
      id = create_packing_method
      attrs = interactor.send(:repo).find_hash(:packing_methods, id).reject { |k, _| %i[id packing_method_code].include?(k) }
      res = interactor.update_packing_method(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:packing_method_code]
    end

    def test_delete_packing_method
      id = create_packing_method
      assert_count_changed(:packing_methods, -1) do
        res = interactor.delete_packing_method(id)
        assert res.success, res.message
      end
    end

    private

    def packing_method_attrs
      {
        id: 1,
        packing_method_code: Faker::Lorem.unique.word,
        description: 'ABC',
        actual_count_reduction_factor: 1.0,
        active: true
      }
    end

    def fake_packing_method(overrides = {})
      PackingMethod.new(packing_method_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PackingMethodInteractor.new(current_user, {}, {}, {})
    end
  end
end
