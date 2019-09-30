# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestVesselTypePermission < Minitest::Test
    include Crossbeams::Responses
    include VesselTypeFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        voyage_type_id: 1,
        vessel_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
      MasterfilesApp::VesselType.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::VesselType.call(:create)
      assert res.success, 'Should always be able to create a vessel_type'
    end

    def test_edit
      MasterfilesApp::VesselTypeRepo.any_instance.stubs(:find_vessel_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::VesselType.call(:edit, 1)
      assert res.success, 'Should be able to edit a vessel_type'
    end

    def test_delete
      MasterfilesApp::VesselTypeRepo.any_instance.stubs(:find_vessel_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::VesselType.call(:delete, 1)
      assert res.success, 'Should be able to delete a vessel_type'
    end
  end
end
