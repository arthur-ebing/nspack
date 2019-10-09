# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPalletVerificationFailureReasonPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        reason: Faker::Lorem.unique.word,
        active: true
      }
      MasterfilesApp::PalletVerificationFailureReason.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::PalletVerificationFailureReason.call(:create)
      assert res.success, 'Should always be able to create a pallet_verification_failure_reason'
    end

    def test_edit
      MasterfilesApp::QualityRepo.any_instance.stubs(:find_pallet_verification_failure_reason).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PalletVerificationFailureReason.call(:edit, 1)
      assert res.success, 'Should be able to edit a pallet_verification_failure_reason'
    end

    def test_delete
      MasterfilesApp::QualityRepo.any_instance.stubs(:find_pallet_verification_failure_reason).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PalletVerificationFailureReason.call(:delete, 1)
      assert res.success, 'Should be able to delete a pallet_verification_failure_reason'
    end
  end
end
