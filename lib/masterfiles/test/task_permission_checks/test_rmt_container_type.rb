# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestRmtContainerTypePermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        container_type_code: 'ABC',
        description: 'ABC',
        active: true,
        tare_weight: 2.3,
        rmt_inner_container_type_id: 1
      }
      MasterfilesApp::RmtContainerType.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::RmtContainerType.call(:create)
      assert res.success, 'Should always be able to create a rmt_container_type'
    end

    def test_edit
      MasterfilesApp::RmtContainerTypeRepo.any_instance.stubs(:find_rmt_container_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::RmtContainerType.call(:edit, 1)
      assert res.success, 'Should be able to edit a rmt_container_type'

      # MasterfilesApp::RmtContainerTypeRepo.any_instance.stubs(:find_rmt_container_type).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::RmtContainerType.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed rmt_container_type'
    end

    def test_delete
      MasterfilesApp::RmtContainerTypeRepo.any_instance.stubs(:find_rmt_container_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::RmtContainerType.call(:delete, 1)
      assert res.success, 'Should be able to delete a rmt_container_type'

      # MasterfilesApp::RmtContainerTypeRepo.any_instance.stubs(:find_rmt_container_type).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::RmtContainerType.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed rmt_container_type'
    end

    # def test_complete
    #   MasterfilesApp::RmtContainerTypeRepo.any_instance.stubs(:find_rmt_container_type).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::RmtContainerType.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a rmt_container_type'

    #   MasterfilesApp::RmtContainerTypeRepo.any_instance.stubs(:find_rmt_container_type).returns(entity(completed: true))
    #   res = MasterfilesApp::TaskPermissionCheck::RmtContainerType.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed rmt_container_type'
    # end

    # def test_approve
    #   MasterfilesApp::RmtContainerTypeRepo.any_instance.stubs(:find_rmt_container_type).returns(entity(completed: true, approved: false))
    #   res = MasterfilesApp::TaskPermissionCheck::RmtContainerType.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed rmt_container_type'

    #   MasterfilesApp::RmtContainerTypeRepo.any_instance.stubs(:find_rmt_container_type).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::RmtContainerType.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed rmt_container_type'

    #   MasterfilesApp::RmtContainerTypeRepo.any_instance.stubs(:find_rmt_container_type).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::RmtContainerType.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved rmt_container_type'
    # end

    # def test_reopen
    #   MasterfilesApp::RmtContainerTypeRepo.any_instance.stubs(:find_rmt_container_type).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::RmtContainerType.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a rmt_container_type that has not been approved'

    #   MasterfilesApp::RmtContainerTypeRepo.any_instance.stubs(:find_rmt_container_type).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::RmtContainerType.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved rmt_container_type'
    # end
  end
end
