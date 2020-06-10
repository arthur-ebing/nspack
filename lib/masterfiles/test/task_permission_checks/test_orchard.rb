# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestOrchardPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        farm_id: 1,
        puc_id: 1,
        farm_manager_party_role_id: 1,
        farm_section_name: 'ABC',
        orchard_code: 'ABC',
        description: 'ABC',
        cultivar_ids: [1, 2, 3],
        active: true,
        puc_code: 'ABC',
        cultivar_names: 'ABC'
      }
      MasterfilesApp::Orchard.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::Orchard.call(:create)
      assert res.success, 'Should always be able to create a orchard'
    end

    def test_edit
      MasterfilesApp::FarmRepo.any_instance.stubs(:find_orchard).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Orchard.call(:edit, 1)
      assert res.success, 'Should be able to edit a orchard'
    end

    def test_delete
      MasterfilesApp::FarmRepo.any_instance.stubs(:find_orchard).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Orchard.call(:delete, 1)
      assert res.success, 'Should be able to delete a orchard'
    end
  end
end
