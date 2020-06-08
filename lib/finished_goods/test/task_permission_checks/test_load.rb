# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestLoadPermission < Minitest::Test
    include Crossbeams::Responses
    include LoadFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        load_id: 1,
        depot_id: 1,
        customer_party_role_id: 1,
        consignee_party_role_id: 1,
        billing_client_party_role_id: 1,
        exporter_party_role_id: 1,
        final_receiver_party_role_id: 1,
        final_destination_id: 1,
        pol_voyage_port_id: 1,
        pol_port_id: 1,
        pod_voyage_port_id: 1,
        pod_port_id: 1,
        voyage_type_id: 1,
        vessel_id: 1,
        voyage_id: 1,
        eta: '2010-01-01 12:00',
        ata: '2010-01-01 12:00',
        etd: '2010-01-01 12:00',
        atd: '2010-01-01 12:00',
        voyage_number: Faker::Lorem.unique.word,
        voyage_code: Faker::Lorem.unique.word,
        order_number: Faker::Lorem.unique.word,
        container_code: Faker::Lorem.unique.word,
        year: 2020,
        edi_file_name: 'ABC',
        booking_reference: 'ABC',
        memo_pad: 'ABC',
        customer_order_number: 'ABC',
        customer_reference: 'ABC',
        exporter_certificate_code: 'ABC',
        shipped_at: '2010-01-01 12:00',
        requires_temp_tail: false,
        allocated_at: '2010-01-01 12:00',
        shipping_line_party_role_id: 1,
        shipper_party_role_id: 1,
        transfer_load: false,
        vehicle_number: 'ABC',
        allocated: false,
        container: false,
        loaded: false,
        shipped: false,
        edi: false,
        active: true,
        vehicle: false
      }
      FinishedGoodsApp::LoadFlat.new(base_attrs.merge(attrs))
    end

    def test_create
      res = FinishedGoodsApp::TaskPermissionCheck::Load.call(:create)
      assert res.success, 'Should always be able to create a load'
    end

    def test_edit
      FinishedGoodsApp::LoadRepo.any_instance.stubs(:find_load_flat).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::Load.call(:edit, 1)
      assert res.success, 'Should be able to edit a load'
    end

    def test_delete
      FinishedGoodsApp::LoadRepo.any_instance.stubs(:find_load_flat).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::Load.call(:delete, 1)
      assert res.success, 'Should be able to delete a load'
    end
  end
end
