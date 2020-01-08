# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPortPermission < Minitest::Test
    include Crossbeams::Responses
    include PortFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        city_id: 1,
        port_code: Faker::Lorem.unique.word,
        description: 'ABC',
        port_type_ids: [1, 2, 3],
        voyage_type_ids: [1, 2, 3],
        active: true
      }
      MasterfilesApp::Port.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::Port.call(:create)
      assert res.success, 'Should always be able to create a port'
    end

    def test_edit
      MasterfilesApp::PortRepo.any_instance.stubs(:find_port).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Port.call(:edit, 1)
      assert res.success, 'Should be able to edit a port'
    end

    def test_delete
      MasterfilesApp::PortRepo.any_instance.stubs(:find_port).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Port.call(:delete, 1)
      assert res.success, 'Should be able to delete a port'
    end
  end
end
