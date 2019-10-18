# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestVesselPermission < Minitest::Test
    include Crossbeams::Responses
    include VesselFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        vessel_type_id: 1,
        vessel_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
      MasterfilesApp::Vessel.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::Vessel.call(:create)
      assert res.success, 'Should always be able to create a vessel'
    end

    def test_edit
      MasterfilesApp::VesselRepo.any_instance.stubs(:find_vessel).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Vessel.call(:edit, 1)
      assert res.success, 'Should be able to edit a vessel'
    end

    def test_delete
      MasterfilesApp::VesselRepo.any_instance.stubs(:find_vessel).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Vessel.call(:delete, 1)
      assert res.success, 'Should be able to delete a vessel'
    end
  end
end
