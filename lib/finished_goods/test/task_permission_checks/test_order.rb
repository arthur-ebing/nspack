# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestOrderPermission < Minitest::Test
    include Crossbeams::Responses
    include OrderFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        order_id: 1,
        order_type_id: 1,
        order_type: 'ABC',
        customer_party_role_id: 1,
        customer: 'ABC',
        sales_person_party_role_id: 1,
        sales_person: 'ABC',
        contact_party_role_id: 1,
        contact: 'ABC',
        currency_id: 1,
        currency: 'ABC',
        deal_type_id: 1,
        deal_type: 'ABC',
        incoterm_id: 1,
        incoterm: 'ABC',
        customer_payment_term_set_id: 1,
        customer_payment_term_set: 'ABC',
        target_customer_party_role_id: 1,
        target_customer: 'ABC',
        exporter_party_role_id: 1,
        exporter: 'ABC',
        packed_tm_group_id: 1,
        packed_tm_group: 'ABC',
        final_receiver_party_role_id: 1,
        final_receiver: 'ABC',
        marketing_org_party_role_id: 1,
        marketing_org: 'ABC',
        allocated: false,
        shipped: false,
        completed: false,
        completed_at: '2010-01-01 12:00',
        customer_order_number: Faker::Lorem.unique.word,
        internal_order_number: 'ABC',
        order_number: 'ABC',
        contact_person_ids: [1],
        remarks: 'ABC',
        pricing_per_kg: false,
        active: true
      }
      FinishedGoodsApp::Order.new(base_attrs.merge(attrs))
    end

    def test_create
      res = FinishedGoodsApp::TaskPermissionCheck::Order.call(:create)
      assert res.success, 'Should always be able to create a order'
    end

    def test_edit
      FinishedGoodsApp::OrderRepo.any_instance.stubs(:find_order).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::Order.call(:edit, 1)
      assert res.success, 'Should be able to edit a order'
    end

    def test_delete
      FinishedGoodsApp::OrderRepo.any_instance.stubs(:find_order).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::Order.call(:delete, 1)
      assert res.success, 'Should be able to delete a order'
    end
  end
end
