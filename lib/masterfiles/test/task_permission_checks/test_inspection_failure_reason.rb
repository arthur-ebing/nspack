# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestInspectionFailureReasonPermission < Minitest::Test
    include Crossbeams::Responses
    include InspectionFailureReasonFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        inspection_failure_type_id: 1,
        failure_reason: Faker::Lorem.unique.word,
        description: 'ABC',
        main_factor: false,
        secondary_factor: false,
        active: true
      }
      MasterfilesApp::InspectionFailureReason.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::InspectionFailureReason.call(:create)
      assert res.success, 'Should always be able to create a inspection_failure_reason'
    end

    def test_edit
      MasterfilesApp::InspectionFailureReasonRepo.any_instance.stubs(:find_inspection_failure_reason).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::InspectionFailureReason.call(:edit, 1)
      assert res.success, 'Should be able to edit a inspection_failure_reason'

      # MasterfilesApp::InspectionFailureReasonRepo.any_instance.stubs(:find_inspection_failure_reason).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::InspectionFailureReason.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed inspection_failure_reason'
    end

    def test_delete
      MasterfilesApp::InspectionFailureReasonRepo.any_instance.stubs(:find_inspection_failure_reason).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::InspectionFailureReason.call(:delete, 1)
      assert res.success, 'Should be able to delete a inspection_failure_reason'

      # MasterfilesApp::InspectionFailureReasonRepo.any_instance.stubs(:find_inspection_failure_reason).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::InspectionFailureReason.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed inspection_failure_reason'
    end

    # def test_complete
    #   MasterfilesApp::InspectionFailureReasonRepo.any_instance.stubs(:find_inspection_failure_reason).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::InspectionFailureReason.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a inspection_failure_reason'

    #   MasterfilesApp::InspectionFailureReasonRepo.any_instance.stubs(:find_inspection_failure_reason).returns(entity(completed: true))
    #   res = MasterfilesApp::TaskPermissionCheck::InspectionFailureReason.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed inspection_failure_reason'
    # end

    # def test_approve
    #   MasterfilesApp::InspectionFailureReasonRepo.any_instance.stubs(:find_inspection_failure_reason).returns(entity(completed: true, approved: false))
    #   res = MasterfilesApp::TaskPermissionCheck::InspectionFailureReason.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed inspection_failure_reason'

    #   MasterfilesApp::InspectionFailureReasonRepo.any_instance.stubs(:find_inspection_failure_reason).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::InspectionFailureReason.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed inspection_failure_reason'

    #   MasterfilesApp::InspectionFailureReasonRepo.any_instance.stubs(:find_inspection_failure_reason).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::InspectionFailureReason.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved inspection_failure_reason'
    # end

    # def test_reopen
    #   MasterfilesApp::InspectionFailureReasonRepo.any_instance.stubs(:find_inspection_failure_reason).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::InspectionFailureReason.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a inspection_failure_reason that has not been approved'

    #   MasterfilesApp::InspectionFailureReasonRepo.any_instance.stubs(:find_inspection_failure_reason).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::InspectionFailureReason.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved inspection_failure_reason'
    # end
  end
end
