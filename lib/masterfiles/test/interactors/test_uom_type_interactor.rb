# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestUomTypeInteractor < MiniTestWithHooks
    include GeneralFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::GeneralRepo)
    end

    def test_uom_type
      MasterfilesApp::GeneralRepo.any_instance.stubs(:find_uom_type).returns(fake_uom_type)
      entity = interactor.send(:uom_type, 1)
      assert entity.is_a?(UomType)
    end

    def test_create_uom_type
      attrs = fake_uom_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_uom_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(UomType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_uom_type_fail
      attrs = fake_uom_type(code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_uom_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:code]
    end

    def test_update_uom_type
      id = create_uom_type
      attrs = interactor.send(:repo).find_hash(:uom_types, id).reject { |k, _| k == :id }
      value = attrs[:code]
      attrs[:code] = 'a_change'
      res = interactor.update_uom_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(UomType, res.instance)
      assert_equal 'a_change', res.instance.code
      refute_equal value, res.instance.code
    end

    def test_update_uom_type_fail
      id = create_uom_type
      attrs = interactor.send(:repo).find_hash(:uom_types, id)
      attrs.delete(:code)
      value = attrs[:id]
      attrs[:id] = 222
      res = interactor.update_uom_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:code]
      after = interactor.send(:repo).find_hash(:uom_types, id)
      refute_equal 222, after[:id]
      assert_equal value, after[:id]
    end

    def test_delete_uom_type
      id = create_uom_type(force_create: true)
      assert_count_changed(:uom_types, -1) do
        res = interactor.delete_uom_type(id)
        assert res.success, res.message
      end
    end

    private

    def uom_type_attrs
      {
        id: 1,
        code: Faker::Lorem.unique.word,
        active: true
      }
    end

    def fake_uom_type(overrides = {})
      UomType.new(uom_type_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= UomTypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
