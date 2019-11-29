# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestInspectionFailureTypeInteractor < MiniTestWithHooks
    include InspectionFailureTypeFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::InspectionFailureTypeRepo)
    end

    def test_inspection_failure_type
      MasterfilesApp::InspectionFailureTypeRepo.any_instance.stubs(:find_inspection_failure_type).returns(fake_inspection_failure_type)
      entity = interactor.send(:inspection_failure_type, 1)
      assert entity.is_a?(InspectionFailureType)
    end

    def test_create_inspection_failure_type
      attrs = fake_inspection_failure_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_inspection_failure_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(InspectionFailureType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_inspection_failure_type_fail
      attrs = fake_inspection_failure_type(failure_type_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_inspection_failure_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:failure_type_code]
    end

    def test_update_inspection_failure_type
      id = create_inspection_failure_type
      attrs = interactor.send(:repo).find_hash(:inspection_failure_types, id).reject { |k, _| k == :id }
      value = attrs[:failure_type_code]
      attrs[:failure_type_code] = 'a_change'
      res = interactor.update_inspection_failure_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(InspectionFailureType, res.instance)
      assert_equal 'a_change', res.instance.failure_type_code
      refute_equal value, res.instance.failure_type_code
    end

    def test_update_inspection_failure_type_fail
      id = create_inspection_failure_type
      attrs = interactor.send(:repo).find_hash(:inspection_failure_types, id).reject { |k, _| %i[id failure_type_code].include?(k) }
      res = interactor.update_inspection_failure_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:failure_type_code]
    end

    def test_delete_inspection_failure_type
      id = create_inspection_failure_type
      assert_count_changed(:inspection_failure_types, -1) do
        res = interactor.delete_inspection_failure_type(id)
        assert res.success, res.message
      end
    end

    private

    def inspection_failure_type_attrs
      {
        id: 1,
        failure_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
    end

    def fake_inspection_failure_type(overrides = {})
      InspectionFailureType.new(inspection_failure_type_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= InspectionFailureTypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
