# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestOrderItemPermission < Minitest::Test
    include Crossbeams::Responses
    include OrderFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        order_id: 1,
        order: 1,
        load_id: 1,
        load: 1,
        packed_tm_group_id: 1,
        marketing_org_party_role_id: 1,
        target_customer_party_role_id: 1,
        commodity_id: 1,
        commodity: 'ABC',
        basic_pack_id: 1,
        basic_pack: 'ABC',
        standard_pack_id: 1,
        standard_pack: 'ABC',
        actual_count_id: 1,
        actual_count: 'ABC',
        size_reference_id: 1,
        size_reference: 'ABC',
        grade_id: 1,
        grade: 'ABC',
        mark_id: 1,
        mark: 'ABC',
        marketing_variety_id: 1,
        marketing_variety: 'ABC',
        inventory_id: 1,
        inventory: 'ABC',
        carton_quantity: 1,
        price_per_carton: 1.0,
        price_per_kg: 1.0,
        sell_by_code: Faker::Lorem.unique.word,
        pallet_format_id: 1,
        pallet_format: 'ABC',
        pm_mark_id: 1,
        pkg_mark: 'ABC',
        pm_bom_id: 1,
        pkg_bom: 'ABC',
        rmt_class_id: 1,
        rmt_class: 'ABC',
        treatment_id: 1,
        treatment: 'ABC',
        active: true
      }
      FinishedGoodsApp::OrderItem.new(base_attrs.merge(attrs))
    end

    def test_create
      res = FinishedGoodsApp::TaskPermissionCheck::OrderItem.call(:create)
      assert res.success, 'Should always be able to create a order_item'
    end

    def test_edit
      FinishedGoodsApp::OrderRepo.any_instance.stubs(:find_order_item).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::OrderItem.call(:edit, 1)
      assert res.success, 'Should be able to edit a order_item'
    end

    def test_delete
      FinishedGoodsApp::OrderRepo.any_instance.stubs(:find_order_item).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::OrderItem.call(:delete, 1)
      assert res.success, 'Should be able to delete a order_item'
    end
  end
end
