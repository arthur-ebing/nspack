# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestInspectionFailureReasonInteractor < MiniTestWithHooks
    include InspectionFailureReasonFactory
    include InspectionFailureTypeFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::InspectionFailureReasonRepo)
    end

    def test_inspection_failure_reason
      MasterfilesApp::InspectionFailureReasonRepo.any_instance.stubs(:find_inspection_failure_reason).returns(fake_inspection_failure_reason)
      entity = interactor.send(:inspection_failure_reason, 1)
      assert entity.is_a?(InspectionFailureReason)
    end

    def test_create_inspection_failure_reason
      attrs = fake_inspection_failure_reason.to_h.reject { |k, _| k == :id }
      res = interactor.create_inspection_failure_reason(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(InspectionFailureReason, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_inspection_failure_reason_fail
      attrs = fake_inspection_failure_reason(failure_reason: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_inspection_failure_reason(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:failure_reason]
    end

    def test_update_inspection_failure_reason
      id = create_inspection_failure_reason
      attrs = interactor.send(:repo).find_hash(:inspection_failure_reasons, id).reject { |k, _| k == :id }
      value = attrs[:failure_reason]
      attrs[:failure_reason] = 'a_change'
      res = interactor.update_inspection_failure_reason(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(InspectionFailureReason, res.instance)
      assert_equal 'a_change', res.instance.failure_reason
      refute_equal value, res.instance.failure_reason
    end

    def test_update_inspection_failure_reason_fail
      id = create_inspection_failure_reason
      attrs = interactor.send(:repo).find_hash(:inspection_failure_reasons, id).reject { |k, _| %i[id failure_reason].include?(k) }
      res = interactor.update_inspection_failure_reason(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:failure_reason]
    end

    def test_delete_inspection_failure_reason
      id = create_inspection_failure_reason
      assert_count_changed(:inspection_failure_reasons, -1) do
        res = interactor.delete_inspection_failure_reason(id)
        assert res.success, res.message
      end
    end

    private

    def inspection_failure_reason_attrs
      inspection_failure_type_id = create_inspection_failure_type

      {
        id: 1,
        inspection_failure_type_id: inspection_failure_type_id,
        failure_reason: Faker::Lorem.unique.word,
        description: 'ABC',
        main_factor: false,
        secondary_factor: false,
        active: true
      }
    end

    def fake_inspection_failure_reason(overrides = {})
      InspectionFailureReason.new(inspection_failure_reason_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= InspectionFailureReasonInteractor.new(current_user, {}, {}, {})
    end
  end
end
