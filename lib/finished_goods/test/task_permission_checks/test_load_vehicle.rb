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

      # FinishedGoodsApp::LoadVehicleRepo.any_instance.stubs(:find_load_vehicle).returns(entity(completed: true))
      # res = FinishedGoodsApp::TaskPermissionCheck::LoadVehicle.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed load_vehicle'
    end

    def test_delete
      FinishedGoodsApp::LoadVehicleRepo.any_instance.stubs(:find_load_vehicle).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::LoadVehicle.call(:delete, 1)
      assert res.success, 'Should be able to delete a load_vehicle'

      # FinishedGoodsApp::LoadVehicleRepo.any_instance.stubs(:find_load_vehicle).returns(entity(completed: true))
      # res = FinishedGoodsApp::TaskPermissionCheck::LoadVehicle.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed load_vehicle'
    end

    # def test_complete
    #   FinishedGoodsApp::LoadVehicleRepo.any_instance.stubs(:find_load_vehicle).returns(entity)
    #   res = FinishedGoodsApp::TaskPermissionCheck::LoadVehicle.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a load_vehicle'

    #   FinishedGoodsApp::LoadVehicleRepo.any_instance.stubs(:find_load_vehicle).returns(entity(completed: true))
    #   res = FinishedGoodsApp::TaskPermissionCheck::LoadVehicle.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed load_vehicle'
    # end

    # def test_approve
    #   FinishedGoodsApp::LoadVehicleRepo.any_instance.stubs(:find_load_vehicle).returns(entity(completed: true, approved: false))
    #   res = FinishedGoodsApp::TaskPermissionCheck::LoadVehicle.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed load_vehicle'

    #   FinishedGoodsApp::LoadVehicleRepo.any_instance.stubs(:find_load_vehicle).returns(entity)
    #   res = FinishedGoodsApp::TaskPermissionCheck::LoadVehicle.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed load_vehicle'

    #   FinishedGoodsApp::LoadVehicleRepo.any_instance.stubs(:find_load_vehicle).returns(entity(completed: true, approved: true))
    #   res = FinishedGoodsApp::TaskPermissionCheck::LoadVehicle.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved load_vehicle'
    # end

    # def test_reopen
    #   FinishedGoodsApp::LoadVehicleRepo.any_instance.stubs(:find_load_vehicle).returns(entity)
    #   res = FinishedGoodsApp::TaskPermissionCheck::LoadVehicle.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a load_vehicle that has not been approved'

    #   FinishedGoodsApp::LoadVehicleRepo.any_instance.stubs(:find_load_vehicle).returns(entity(completed: true, approved: true))
    #   res = FinishedGoodsApp::TaskPermissionCheck::LoadVehicle.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved load_vehicle'
    # end
  end
end
