# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestOrderItemInteractor < MiniTestWithHooks
    include OrderFactory
    include MasterfilesApp::FinanceFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::TargetMarketFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::FruitFactory
    include MasterfilesApp::GeneralFactory
    include MasterfilesApp::MarketingFactory
    include MasterfilesApp::PackagingFactory
    include RawMaterialsApp::RmtBinFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(FinishedGoodsApp::OrderRepo)
    end

    def test_order_item
      FinishedGoodsApp::OrderRepo.any_instance.stubs(:find_order_item).returns(fake_order_item)
      entity = interactor.send(:order_item, 1)
      assert entity.is_a?(OrderItem)
    end

    def test_create_order_item
      attrs = fake_order_item.to_h.reject { |k, _| k == :id }
      res = interactor.create_order_item(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(OrderItem, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_order_item_fail
      attrs = fake_order_item(order_id: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_order_item(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:order_id]
    end

    def test_update_order_item
      id = create_order_item
      attrs = interactor.send(:repo).find_hash(:order_items, id).reject { |k, _| k == :id }
      value = attrs[:sell_by_code]
      attrs[:sell_by_code] = 'a_change'
      res = interactor.update_order_item(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(OrderItem, res.instance)
      assert_equal 'a_change', res.instance.sell_by_code
      refute_equal value, res.instance.sell_by_code
    end

    def test_update_order_item_fail
      id = create_order_item
      attrs = interactor.send(:repo).find_hash(:order_items, id).reject { |k, _| %i[id sell_by_code].include?(k) }
      res = interactor.update_order_item(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:sell_by_code]
    end

    def test_delete_order_item
      id = create_order_item
      assert_count_changed(:order_items, -1) do
        res = interactor.delete_order_item(id)
        assert res.success, res.message
      end
    end

    private

    def order_item_attrs
      order_id = create_order
      commodity_id = create_commodity
      basic_pack_code_id = create_basic_pack
      standard_pack_code_id = create_standard_pack
      fruit_actual_counts_for_pack_id = create_fruit_actual_counts_for_pack
      fruit_size_reference_id = create_fruit_size_reference
      grade_id = create_grade
      mark_id = create_mark
      marketing_variety_id = create_marketing_variety
      inventory_code_id = create_inventory_code
      pallet_format_id = create_pallet_format
      pm_mark_id = create_pm_mark
      pm_bom_id = create_pm_bom
      rmt_class_id = create_rmt_class
      treatment_id = create_treatment

      {
        id: 1,
        order_id: order_id,
        order: order_id,
        load_id: nil,
        load: nil,
        commodity_id: commodity_id,
        commodity: 'ABC',
        basic_pack_id: basic_pack_code_id,
        basic_pack: 'ABC',
        standard_pack_id: standard_pack_code_id,
        standard_pack: 'ABC',
        actual_count_id: fruit_actual_counts_for_pack_id,
        actual_count: 'ABC',
        size_reference_id: fruit_size_reference_id,
        size_reference: 'ABC',
        grade_id: grade_id,
        grade: 'ABC',
        mark_id: mark_id,
        mark: 'ABC',
        marketing_variety_id: marketing_variety_id,
        marketing_variety: 'ABC',
        inventory_id: inventory_code_id,
        inventory: 'ABC',
        carton_quantity: 1,
        price_per_carton: 1.0,
        price_per_kg: 1.0,
        sell_by_code: Faker::Lorem.unique.word,
        pallet_format_id: pallet_format_id,
        pallet_format: 'ABC',
        pm_mark_id: pm_mark_id,
        pkg_mark: 'ABC',
        pm_bom_id: pm_bom_id,
        pkg_bom: 'ABC',
        rmt_class_id: rmt_class_id,
        rmt_class: 'ABC',
        treatment_id: treatment_id,
        treatment: 'ABC',
        active: true
      }
    end

    def fake_order_item(overrides = {})
      OrderItem.new(order_item_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= OrderItemInteractor.new(current_user, {}, {}, {})
    end
  end
end
