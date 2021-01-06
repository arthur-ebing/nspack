# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestRegisteredOrchardPermission < Minitest::Test
    include Crossbeams::Responses
    include FarmFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        orchard_code: Faker::Lorem.unique.word,
        cultivar_code: 'ABC',
        puc_code: 'ABC',
        description: 'ABC',
        marketing_orchard: false,
        active: true
      }
      MasterfilesApp::RegisteredOrchard.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::RegisteredOrchard.call(:create)
      assert res.success, 'Should always be able to create a registered_orchard'
    end

    def test_edit
      MasterfilesApp::FarmRepo.any_instance.stubs(:find_registered_orchard).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::RegisteredOrchard.call(:edit, 1)
      assert res.success, 'Should be able to edit a registered_orchard'
    end

    def test_delete
      MasterfilesApp::FarmRepo.any_instance.stubs(:find_registered_orchard).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::RegisteredOrchard.call(:delete, 1)
      assert res.success, 'Should be able to delete a registered_orchard'
    end
  end
end
