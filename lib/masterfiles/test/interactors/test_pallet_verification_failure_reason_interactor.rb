# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPalletVerificationFailureReasonInteractor < MiniTestWithHooks
    include QualityFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::QualityRepo)
    end

    def test_pallet_verification_failure_reason
      MasterfilesApp::QualityRepo.any_instance.stubs(:find_pallet_verification_failure_reason).returns(fake_pallet_verification_failure_reason)
      entity = interactor.send(:pallet_verification_failure_reason, 1)
      assert entity.is_a?(PalletVerificationFailureReason)
    end

    def test_create_pallet_verification_failure_reason
      attrs = fake_pallet_verification_failure_reason.to_h.reject { |k, _| k == :id }
      res = interactor.create_pallet_verification_failure_reason(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PalletVerificationFailureReason, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_pallet_verification_failure_reason_fail
      attrs = fake_pallet_verification_failure_reason(reason: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_pallet_verification_failure_reason(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:reason]
    end

    def test_update_pallet_verification_failure_reason
      id = create_pallet_verification_failure_reason
      attrs = interactor.send(:repo).find_hash(:pallet_verification_failure_reasons, id).reject { |k, _| k == :id }
      value = attrs[:reason]
      attrs[:reason] = 'a_change'
      res = interactor.update_pallet_verification_failure_reason(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PalletVerificationFailureReason, res.instance)
      assert_equal 'a_change', res.instance.reason
      refute_equal value, res.instance.reason
    end

    def test_update_pallet_verification_failure_reason_fail
      id = create_pallet_verification_failure_reason
      attrs = interactor.send(:repo).find_hash(:pallet_verification_failure_reasons, id).reject { |k, _| %i[id reason].include?(k) }
      res = interactor.update_pallet_verification_failure_reason(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:reason]
    end

    def test_delete_pallet_verification_failure_reason
      id = create_pallet_verification_failure_reason
      assert_count_changed(:pallet_verification_failure_reasons, -1) do
        res = interactor.delete_pallet_verification_failure_reason(id)
        assert res.success, res.message
      end
    end

    private

    def pallet_verification_failure_reason_attrs
      {
        id: 1,
        reason: Faker::Lorem.unique.word,
        active: true
      }
    end

    def fake_pallet_verification_failure_reason(overrides = {})
      PalletVerificationFailureReason.new(pallet_verification_failure_reason_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PalletVerificationFailureReasonInteractor.new(current_user, {}, {}, {})
    end
  end
end
