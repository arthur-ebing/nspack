# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestFarmPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        owner_party_role_id: 1,
        pdn_region_id: 1,
        farm_group_id: 1,
        farm_code: 'ABC',
        description: 'ABC',
        active: true,
        puc_id: 1,
        farms_pucs_ids: [1, 2],
        farm_group_code: 'ABC',
        owner_party_role: 'ABC',
        pdn_region_production_region_code: 'ABC',
        location_id: 1,
        location_long_code: 'ABC'
      }
      MasterfilesApp::Farm.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::Farm.call(:create)
      assert res.success, 'Should always be able to create a farm'
    end

    def test_edit
      MasterfilesApp::FarmRepo.any_instance.stubs(:find_farm).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Farm.call(:edit, 1)
      assert res.success, 'Should be able to edit a farm'
    end

    def test_delete
      MasterfilesApp::FarmRepo.any_instance.stubs(:find_farm).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Farm.call(:delete, 1)
      assert res.success, 'Should be able to delete a farm'
    end
  end
end
