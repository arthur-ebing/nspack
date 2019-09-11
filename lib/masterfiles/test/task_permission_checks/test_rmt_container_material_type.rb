# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestRmtContainerMaterialTypePermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        rmt_container_type_id: 1,
        container_material_type_code: 'ABC',
        description: 'ABC',
        tare_weight: 1.0,
        active: true,
        party_role_ids: nil,
        container_material_owners: nil
      }
      MasterfilesApp::RmtContainerMaterialType.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::RmtContainerMaterialType.call(:create)
      assert res.success, 'Should always be able to create a rmt_container_material_type'
    end

    def test_edit
      MasterfilesApp::RmtContainerMaterialTypeRepo.any_instance.stubs(:find_rmt_container_material_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::RmtContainerMaterialType.call(:edit, 1)
      assert res.success, 'Should be able to edit a rmt_container_material_type'

      # MasterfilesApp::RmtContainerMaterialTypeRepo.any_instance.stubs(:find_rmt_container_material_type).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::RmtContainerMaterialType.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed rmt_container_material_type'
    end

    def test_delete
      MasterfilesApp::RmtContainerMaterialTypeRepo.any_instance.stubs(:find_rmt_container_material_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::RmtContainerMaterialType.call(:delete, 1)
      assert res.success, 'Should be able to delete a rmt_container_material_type'

      # MasterfilesApp::RmtContainerMaterialTypeRepo.any_instance.stubs(:find_rmt_container_material_type).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::RmtContainerMaterialType.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed rmt_container_material_type'
    end

    # def test_complete
    #   MasterfilesApp::RmtContainerMaterialTypeRepo.any_instance.stubs(:find_rmt_container_material_type).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::RmtContainerMaterialType.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a rmt_container_material_type'

    #   MasterfilesApp::RmtContainerMaterialTypeRepo.any_instance.stubs(:find_rmt_container_material_type).returns(entity(completed: true))
    #   res = MasterfilesApp::TaskPermissionCheck::RmtContainerMaterialType.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed rmt_container_material_type'
    # end

    # def test_approve
    #   MasterfilesApp::RmtContainerMaterialTypeRepo.any_instance.stubs(:find_rmt_container_material_type).returns(entity(completed: true, approved: false))
    #   res = MasterfilesApp::TaskPermissionCheck::RmtContainerMaterialType.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed rmt_container_material_type'

    #   MasterfilesApp::RmtContainerMaterialTypeRepo.any_instance.stubs(:find_rmt_container_material_type).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::RmtContainerMaterialType.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed rmt_container_material_type'

    #   MasterfilesApp::RmtContainerMaterialTypeRepo.any_instance.stubs(:find_rmt_container_material_type).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::RmtContainerMaterialType.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved rmt_container_material_type'
    # end

    # def test_reopen
    #   MasterfilesApp::RmtContainerMaterialTypeRepo.any_instance.stubs(:find_rmt_container_material_type).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::RmtContainerMaterialType.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a rmt_container_material_type that has not been approved'

    #   MasterfilesApp::RmtContainerMaterialTypeRepo.any_instance.stubs(:find_rmt_container_material_type).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::RmtContainerMaterialType.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved rmt_container_material_type'
    # end
  end
end
