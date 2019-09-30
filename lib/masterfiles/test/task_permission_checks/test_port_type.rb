# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPortTypePermission < Minitest::Test
    include Crossbeams::Responses
    include PortTypeFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        port_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
      MasterfilesApp::PortType.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::PortType.call(:create)
      assert res.success, 'Should always be able to create a port_type'
    end

    def test_edit
      MasterfilesApp::PortTypeRepo.any_instance.stubs(:find_port_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PortType.call(:edit, 1)
      assert res.success, 'Should be able to edit a port_type'
    end

    def test_delete
      MasterfilesApp::PortTypeRepo.any_instance.stubs(:find_port_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PortType.call(:delete, 1)
      assert res.success, 'Should be able to delete a port_type'
    end
  end
end
