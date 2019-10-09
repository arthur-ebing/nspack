# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestQualityRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_pallet_verification_failure_reasons
    end

    def test_crud_calls
      test_crud_calls_for :pallet_verification_failure_reasons, name: :pallet_verification_failure_reason, wrapper: PalletVerificationFailureReason
    end

    private

    def repo
      QualityRepo.new
    end
  end
end
