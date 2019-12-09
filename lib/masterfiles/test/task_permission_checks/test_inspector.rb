# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestInspectorPermission < Minitest::Test
    include Crossbeams::Responses
    include InspectorFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        inspector_party_role_id: 1,
        tablet_ip_address: Faker::Lorem.unique.word,
        tablet_port_number: 1,
        inspector_code: 'ABC',
        active: true
      }
      MasterfilesApp::Inspector.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::Inspector.call(:create)
      assert res.success, 'Should always be able to create a inspector'
    end

    def test_edit
      MasterfilesApp::InspectorRepo.any_instance.stubs(:find_inspector).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Inspector.call(:edit, 1)
      assert res.success, 'Should be able to edit a inspector'
    end

    def test_delete
      MasterfilesApp::InspectorRepo.any_instance.stubs(:find_inspector).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Inspector.call(:delete, 1)
      assert res.success, 'Should be able to delete a inspector'
    end
  end
end
