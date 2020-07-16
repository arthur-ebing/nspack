# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module RawMaterialsApp
  class TestRmtDeliveryPermission < Minitest::Test
    include Crossbeams::Responses
    # include RmtDeliveryFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        orchard_id: 1, # orchard_id,
        cultivar_id: 1, # cultivar_id,
        rmt_delivery_destination_id: 1, # rmt_delivery_destination_id,
        season_id: 1, # season_id,
        farm_id: 1, # farm_id,
        puc_id: 1, # puc_id,
        truck_registration_number: Faker::Lorem.unique.word,
        reference_number: Faker::Lorem.unique.word,
        qty_damaged_bins: 1,
        qty_empty_bins: 1,
        delivery_tipped: false,
        date_picked: '2010-01-01',
        intake_date: '2010-01-01 12:00',
        date_delivered: '2010-01-01 12:00',
        tipping_complete_date_time: '2010-01-01 12:00',
        active: true
      }
      RawMaterialsApp::RmtDelivery.new(base_attrs.merge(attrs))
    end

    def test_create
      res = RawMaterialsApp::TaskPermissionCheck::RmtDelivery.call(:create)
      assert res.success, 'Should always be able to create a rmt_delivery'
    end

    def test_edit
      RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_delivery).returns(entity)
      res = RawMaterialsApp::TaskPermissionCheck::RmtDelivery.call(:edit, 1)
      assert res.success, 'Should be able to edit a rmt_delivery'

      # RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_delivery).returns(entity(completed: true))
      # res = RawMaterialsApp::TaskPermissionCheck::RmtDelivery.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed rmt_delivery'
    end

    def test_delete
      RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_delivery).returns(entity)
      res = RawMaterialsApp::TaskPermissionCheck::RmtDelivery.call(:delete, 1)
      assert res.success, 'Should be able to delete a rmt_delivery'

      # RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_delivery).returns(entity(completed: true))
      # res = RawMaterialsApp::TaskPermissionCheck::RmtDelivery.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed rmt_delivery'
    end

    # def test_complete
    #   RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_delivery).returns(entity)
    #   res = RawMaterialsApp::TaskPermissionCheck::RmtDelivery.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a rmt_delivery'

    #   RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_delivery).returns(entity(completed: true))
    #   res = RawMaterialsApp::TaskPermissionCheck::RmtDelivery.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed rmt_delivery'
    # end

    # def test_approve
    #   RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_delivery).returns(entity(completed: true, approved: false))
    #   res = RawMaterialsApp::TaskPermissionCheck::RmtDelivery.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed rmt_delivery'

    #   RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_delivery).returns(entity)
    #   res = RawMaterialsApp::TaskPermissionCheck::RmtDelivery.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed rmt_delivery'

    #   RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_delivery).returns(entity(completed: true, approved: true))
    #   res = RawMaterialsApp::TaskPermissionCheck::RmtDelivery.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved rmt_delivery'
    # end

    # def test_reopen
    #   RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_delivery).returns(entity)
    #   res = RawMaterialsApp::TaskPermissionCheck::RmtDelivery.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a rmt_delivery that has not been approved'

    #   RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_delivery).returns(entity(completed: true, approved: true))
    #   res = RawMaterialsApp::TaskPermissionCheck::RmtDelivery.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved rmt_delivery'
    # end
  end
end
