# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestProductionRegionPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        production_region_code: 'ABC',
        description: 'ABC',
        active: true,
        inspection_region: 'ABC'
      }
      MasterfilesApp::ProductionRegion.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::ProductionRegion.call(:create)
      assert res.success, 'Should always be able to create a production_region'
    end

    def test_edit
      MasterfilesApp::FarmRepo.any_instance.stubs(:find_production_region).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::ProductionRegion.call(:edit, 1)
      assert res.success, 'Should be able to edit a production_region'
    end

    def test_delete
      MasterfilesApp::FarmRepo.any_instance.stubs(:find_production_region).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::ProductionRegion.call(:delete, 1)
      assert res.success, 'Should be able to delete a production_region'
    end
  end
end
