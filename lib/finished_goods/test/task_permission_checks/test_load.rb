# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestLoadPermission < Minitest::Test
    include Crossbeams::Responses
    include LoadFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        depot_id: 1,
        customer_party_role_id: 1,
        consignee_party_role_id: 1,
        billing_client_party_role_id: 1,
        exporter_party_role_id: 1,
        final_receiver_party_role_id: 1,
        final_destination_id: 1,
        pol_voyage_port_id: 1,
        pod_voyage_port_id: 1,
        order_number: Faker::Lorem.unique.word,
        edi_file_name: 'ABC',
        customer_order_number: 'ABC',
        customer_reference: 'ABC',
        exporter_certificate_code: 'ABC',
        shipped_date: '2010-01-01 12:00',
        shipped: false,
        transfer_load: false,
        active: true
      }
      FinishedGoodsApp::Load.new(base_attrs.merge(attrs))
    end

    def test_create
      res = FinishedGoodsApp::TaskPermissionCheck::Load.call(:create)
      assert res.success, 'Should always be able to create a load'
    end

    def test_edit
      FinishedGoodsApp::LoadRepo.any_instance.stubs(:find_load).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::Load.call(:edit, 1)
      assert res.success, 'Should be able to edit a load'
    end

    def test_delete
      FinishedGoodsApp::LoadRepo.any_instance.stubs(:find_load).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::Load.call(:delete, 1)
      assert res.success, 'Should be able to delete a load'
    end
  end
end
