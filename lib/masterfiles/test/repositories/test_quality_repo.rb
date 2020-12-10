# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestQualityRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_pallet_verification_failure_reasons
      assert_respond_to repo, :for_select_scrap_reasons
      assert_respond_to repo, :for_select_inspection_failure_reasons
      assert_respond_to repo, :for_select_inspection_failure_types
      assert_respond_to repo, :for_select_inspection_types
    end

    def test_crud_calls
      test_crud_calls_for :pallet_verification_failure_reasons, name: :pallet_verification_failure_reason, wrapper: PalletVerificationFailureReason
      test_crud_calls_for :scrap_reasons, name: :scrap_reason, wrapper: ScrapReason
      test_crud_calls_for :inspection_failure_reasons, name: :inspection_failure_reason, wrapper: InspectionFailureReason
      test_crud_calls_for :inspection_failure_types, name: :inspection_failure_type, wrapper: InspectionFailureType
      test_crud_calls_for :inspection_types, name: :inspection_type, wrapper: InspectionType
    end

    private

    def repo
      QualityRepo.new
    end
  end
end
