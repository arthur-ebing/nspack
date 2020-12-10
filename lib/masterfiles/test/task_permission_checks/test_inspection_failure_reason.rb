# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestInspectionFailureReasonPermission < Minitest::Test
    include Crossbeams::Responses
    include InspectionFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        inspection_failure_type_id: 1,
        failure_type_code: 'ABC',
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
      MasterfilesApp::QualityRepo.any_instance.stubs(:find_inspection_failure_reason).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::InspectionFailureReason.call(:edit, 1)
      assert res.success, 'Should be able to edit a inspection_failure_reason'
    end

    def test_delete
      MasterfilesApp::QualityRepo.any_instance.stubs(:find_inspection_failure_reason).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::InspectionFailureReason.call(:delete, 1)
      assert res.success, 'Should be able to delete a inspection_failure_reason'
    end
  end
end
