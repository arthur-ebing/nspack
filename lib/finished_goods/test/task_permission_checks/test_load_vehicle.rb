# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestLoadVehiclePermission < Minitest::Test
    include Crossbeams::Responses
    include LoadVehicleFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        load_id: 1,
        vehicle_type_id: 1,
        haulier_party_role_id: 1,
        vehicle_number: Faker::Lorem.unique.word,
        vehicle_weight_out: 1.0,
        dispatch_consignment_note_number: 'ABC',
        driver_name: 'ABC',
        driver_cell_number: 'ABC',
        active: true
      }
      FinishedGoodsApp::LoadVehicle.new(base_attrs.merge(attrs))
    end

    def test_create
      res = FinishedGoodsApp::TaskPermissionCheck::LoadVehicle.call(:create)
      assert res.success, 'Should always be able to create a load_vehicle'
    end

    def test_edit
      FinishedGoodsApp::LoadVehicleRepo.any_instance.stubs(:find_load_vehicle).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::LoadVehicle.call(:edit, 1)
      assert res.success, 'Should be able to edit a load_vehicle'
    end

    def test_delete
      FinishedGoodsApp::LoadVehicleRepo.any_instance.stubs(:find_load_vehicle).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::LoadVehicle.call(:delete, 1)
      assert res.success, 'Should be able to delete a load_vehicle'
    end
  end
end
