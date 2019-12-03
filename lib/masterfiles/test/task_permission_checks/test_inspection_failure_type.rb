# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestInspectionFailureTypePermission < Minitest::Test
    include Crossbeams::Responses
    include InspectionFailureTypeFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        failure_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
      MasterfilesApp::InspectionFailureType.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::InspectionFailureType.call(:create)
      assert res.success, 'Should always be able to create a inspection_failure_type'
    end

    def test_edit
      MasterfilesApp::InspectionFailureTypeRepo.any_instance.stubs(:find_inspection_failure_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::InspectionFailureType.call(:edit, 1)
      assert res.success, 'Should be able to edit a inspection_failure_type'

      # MasterfilesApp::InspectionFailureTypeRepo.any_instance.stubs(:find_inspection_failure_type).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::InspectionFailureType.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed inspection_failure_type'
    end

    def test_delete
      MasterfilesApp::InspectionFailureTypeRepo.any_instance.stubs(:find_inspection_failure_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::InspectionFailureType.call(:delete, 1)
      assert res.success, 'Should be able to delete a inspection_failure_type'

      # MasterfilesApp::InspectionFailureTypeRepo.any_instance.stubs(:find_inspection_failure_type).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::InspectionFailureType.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed inspection_failure_type'
    end

    # def test_complete
    #   MasterfilesApp::InspectionFailureTypeRepo.any_instance.stubs(:find_inspection_failure_type).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::InspectionFailureType.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a inspection_failure_type'

    #   MasterfilesApp::InspectionFailureTypeRepo.any_instance.stubs(:find_inspection_failure_type).returns(entity(completed: true))
    #   res = MasterfilesApp::TaskPermissionCheck::InspectionFailureType.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed inspection_failure_type'
    # end

    # def test_approve
    #   MasterfilesApp::InspectionFailureTypeRepo.any_instance.stubs(:find_inspection_failure_type).returns(entity(completed: true, approved: false))
    #   res = MasterfilesApp::TaskPermissionCheck::InspectionFailureType.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed inspection_failure_type'

    #   MasterfilesApp::InspectionFailureTypeRepo.any_instance.stubs(:find_inspection_failure_type).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::InspectionFailureType.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed inspection_failure_type'

    #   MasterfilesApp::InspectionFailureTypeRepo.any_instance.stubs(:find_inspection_failure_type).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::InspectionFailureType.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved inspection_failure_type'
    # end

    # def test_reopen
    #   MasterfilesApp::InspectionFailureTypeRepo.any_instance.stubs(:find_inspection_failure_type).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::InspectionFailureType.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a inspection_failure_type that has not been approved'

    #   MasterfilesApp::InspectionFailureTypeRepo.any_instance.stubs(:find_inspection_failure_type).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::InspectionFailureType.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved inspection_failure_type'
    # end
  end
end
