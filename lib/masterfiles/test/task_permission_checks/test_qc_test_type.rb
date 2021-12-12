# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestQcTestTypePermission < Minitest::Test
    include Crossbeams::Responses
    include QcFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        qc_test_type_name: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
      MasterfilesApp::QcTestType.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::QcTestType.call(:create)
      assert res.success, 'Should always be able to create a qc_test_type'
    end

    def test_edit
      MasterfilesApp::QcRepo.any_instance.stubs(:find_qc_test_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::QcTestType.call(:edit, 1)
      assert res.success, 'Should be able to edit a qc_test_type'

      # MasterfilesApp::QcRepo.any_instance.stubs(:find_qc_test_type).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::QcTestType.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed qc_test_type'
    end

    def test_delete
      MasterfilesApp::QcRepo.any_instance.stubs(:find_qc_test_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::QcTestType.call(:delete, 1)
      assert res.success, 'Should be able to delete a qc_test_type'

      # MasterfilesApp::QcRepo.any_instance.stubs(:find_qc_test_type).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::QcTestType.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed qc_test_type'
    end

    # def test_complete
    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_qc_test_type).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::QcTestType.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a qc_test_type'

    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_qc_test_type).returns(entity(completed: true))
    #   res = MasterfilesApp::TaskPermissionCheck::QcTestType.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed qc_test_type'
    # end

    # def test_approve
    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_qc_test_type).returns(entity(completed: true, approved: false))
    #   res = MasterfilesApp::TaskPermissionCheck::QcTestType.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed qc_test_type'

    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_qc_test_type).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::QcTestType.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed qc_test_type'

    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_qc_test_type).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::QcTestType.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved qc_test_type'
    # end

    # def test_reopen
    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_qc_test_type).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::QcTestType.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a qc_test_type that has not been approved'

    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_qc_test_type).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::QcTestType.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved qc_test_type'
    # end
  end
end
