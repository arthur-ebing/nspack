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
        rmt_load: false,
        customer_party_role_id: 1,
        customer: 'ABC',
        consignee_party_role_id: 1,
        consignee: 'ABC',
        billing_client_party_role_id: 1,
        billing_client: 'ABC',
        exporter_party_role_id: 1,
        exporter: 'ABC',
        final_receiver_party_role_id: 1,
        final_receiver: 'ABC',
        final_destination_id: 1,
        destination_city: 'ABC',
        destination_country: 'ABC',
        destination_region: 'ABC',
        depot_id: 1,
        depot_code: 'ABC',
        pol_voyage_port_id: 1,
        pod_voyage_port_id: 1,
        order_number: Faker::Lorem.unique.word,
        edi_file_name: 'ABC',
        customer_order_number: 'ABC',
        customer_reference: 'ABC',
        exporter_certificate_code: 'ABC',
        shipped_at: '2010-01-01',
        shipped: true,
        allocated_at: '2010-01-01',
        allocated: true,
        transfer_load: false,
        loaded: true,
        requires_temp_tail: true,
        edi: true,
        status: Faker::Lorem.word,
        active: true,

        # voyage
        voyage_type_id: 1,
        vessel_id: 1,
        vessel_code: 'ABC',
        voyage_id: 1,
        voyage_number: Faker::Number.number(digits: 4),
        voyage_code: Faker::Lorem.unique.word,
        year: 2019,
        pol_port_id: 1,
        pol_port_code: 'ABC',
        eta: '2010-01-01',
        ata: '2010-01-01',
        pod_port_id: 1,
        pod_port_code: 'ABC',
        etd: '2010-01-01',
        atd: '2010-01-01',

        # load_voyage
        load_voyage_id: 1,
        shipping_line_party_role_id: 1,
        shipping_line: 'ABC',
        shipper_party_role_id: 1,
        shipper: 'ABC',
        booking_reference: Faker::Lorem.word,
        memo_pad: Faker::Lorem.word,

        # load_vehicle
        vehicle: true,
        load_vehicle_id: 1,
        vehicle_number: Faker::Lorem.word,

        # load_container
        container: true,
        load_container_id: 1,
        verified_gross_weight: 0.1,
        temperature_code: 'ABC',
        container_code: Faker::Lorem.word,

        # pallets
        temp_tail: '123',
        temp_tail_pallet_number: '123',
        pallet_count: 1,
        nett_weight: 1.0,

        # addendum
        addendum: true,
        location_of_issue: '123'
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
      FinishedGoodsApp::LoadRepo.any_instance.stubs(:find_load_flat).returns(entity(allocated: false, vehicle: false, shipped: false))
      res = FinishedGoodsApp::TaskPermissionCheck::Load.call(:delete, 1)
      assert res.success, 'Should be able to delete a load'
    end
  end
end
