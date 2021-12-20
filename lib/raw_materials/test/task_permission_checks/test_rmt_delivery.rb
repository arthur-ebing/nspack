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
        rmt_container_type_id: 1,
        rmt_material_owner_party_role_id: 1,
        rmt_code_id: 1,
        rmt_classifications: [1],
        truck_registration_number: Faker::Lorem.unique.word,
        reference_number: Faker::Lorem.unique.word,
        batch_number: Faker::Lorem.unique.word,
        qty_damaged_bins: 1,
        qty_empty_bins: 1,
        delivery_tipped: false,
        date_picked: '2010-01-01',
        received: true,
        date_delivered: '2010-01-01 12:00',
        tipping_complete_date_time: '2010-01-01 12:00',
        batch_number_updated_at: '2010-01-01 12:00',
        tripsheet_created_at: '2010-01-01 12:00',
        tripsheet_offloaded_at: '2010-01-01 12:00',
        tripsheet_loaded_at: '2010-01-01 12:00',
        active: true,
        rmt_container_material_type_id: 1
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
    end

    def test_delete
      RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_delivery).returns(entity)
      res = RawMaterialsApp::TaskPermissionCheck::RmtDelivery.call(:delete, 1)
      assert res.success, 'Should be able to delete a rmt_delivery'
    end
  end
end
