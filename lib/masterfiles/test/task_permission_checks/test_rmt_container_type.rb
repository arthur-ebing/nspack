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
        rmt_inner_container_type_id: 1,
        rmt_inner_container_type: 'ABC'
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
    end

    def test_delete
      MasterfilesApp::RmtContainerTypeRepo.any_instance.stubs(:find_rmt_container_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::RmtContainerType.call(:delete, 1)
      assert res.success, 'Should be able to delete a rmt_container_type'
    end
  end
end
