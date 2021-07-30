# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestOrderInteractor < MiniTestWithHooks
    include FinishedGoodsApp::OrderFactory
    include MasterfilesApp::FinanceFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::TargetMarketFactory

    include FinishedGoodsApp::LoadFactory
    include FinishedGoodsApp::VoyageFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::DepotFactory
    include MasterfilesApp::VesselFactory
    include MasterfilesApp::PortFactory
    # this can be simplified by including the sub factories in the parent factory.
    include MesscadaApp::PalletFactory
    include MasterfilesApp::PackagingFactory
    include ProductionApp::ResourceFactory
    include MasterfilesApp::LocationFactory
    include MasterfilesApp::FruitFactory
    include ProductionApp::ProductionRunFactory
    include MasterfilesApp::FarmFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::CultivarFactory
    include ProductionApp::ProductSetupFactory
    include MasterfilesApp::TargetMarketFactory
    include MasterfilesApp::GeneralFactory
    include MasterfilesApp::MarketingFactory
    include RawMaterialsApp::RmtBinFactory
    include MasterfilesApp::HRFactory
    include RawMaterialsApp::RmtDeliveryFactory
    include MasterfilesApp::RmtContainerFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(FinishedGoodsApp::OrderRepo)
    end

    def test_order
      FinishedGoodsApp::OrderRepo.any_instance.stubs(:find_order).returns(fake_order)
      entity = interactor.send(:order_entity, 1)
      assert entity.is_a?(Order)
    end

    def test_create_order
      attrs = fake_order.to_h.reject { |k, _| k == :id }
      res = interactor.create_order(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Order, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_order_fail
      attrs = fake_order(customer_party_role_id: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_order(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:customer_party_role_id]
    end

    def test_update_order
      id = create_order
      attrs = interactor.send(:repo).find_hash(:orders, id).reject { |k, _| k == :id }
      value = attrs[:customer_order_number]
      attrs[:customer_order_number] = 'a_change'
      res = interactor.update_order(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Order, res.instance)
      assert_equal 'a_change', res.instance.customer_order_number
      refute_equal value, res.instance.customer_order_number
    end

    def test_update_order_fail
      id = create_order
      attrs = interactor.send(:repo).find_hash(:orders, id).reject { |k, _| %i[id customer_order_number].include?(k) }
      res = interactor.update_order(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:customer_order_number]
    end

    def test_update_order_pallets
      order_id, load_id = create_orders_loads
      pallet_id = create_pallet(load_id: load_id)
      order_item_id = create_order_item(order_id: order_id)
      pallet_sequence_id = create_pallet_sequence(pallet_id: pallet_id, order_item_id: order_item_id)
      new_packed_tm_group_id = create_target_market_group(force_create: true)

      attrs = interactor.send(:repo).find_hash(:orders, order_id).reject { |k, _| k == :id }
      value = attrs[:packed_tm_group_id]
      attrs[:apply_changes_to_pallets] = 't'
      attrs[:packed_tm_group_id] = new_packed_tm_group_id

      res = interactor.update_order(order_id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Order, res.instance)
      assert_equal new_packed_tm_group_id, res.instance.packed_tm_group_id
      assert_equal new_packed_tm_group_id, interactor.send(:repo).get(:pallet_sequences, pallet_sequence_id, :packed_tm_group_id)
      refute_equal value, res.instance.packed_tm_group_id
    end

    def test_delete_order
      id = create_order
      assert_count_changed(:orders, -1) do
        res = interactor.delete_order(id)
        assert res.success, res.message
      end
    end

    private

    def order_attrs
      order_type_id = create_order_type
      customer_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_CUSTOMER)
      sales_person_party_role_id = create_party_role(party_type: 'P', name: AppConst::ROLE_SALES_PERSON)
      contact_party_role_id = create_party_role(party_type: 'P', name: AppConst::ROLE_CUSTOMER_CONTACT_PERSON)
      currency_id = create_currency
      deal_type_id = create_deal_type
      incoterm_id = create_incoterm
      customer_payment_term_set_id = create_customer_payment_term_set
      target_market_group_id = create_target_market_group
      target_customer_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_TARGET_CUSTOMER)
      exporter_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_EXPORTER)
      final_receiver_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_FINAL_RECEIVER)
      marketing_org_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_MARKETER)

      {
        id: 1,
        order_id: 1,
        order_type_id: order_type_id,
        order_type: 'ABC',
        customer_party_role_id: customer_party_role_id,
        customer: 'ABC',
        sales_person_party_role_id: sales_person_party_role_id,
        sales_person: 'ABC',
        contact_party_role_id: contact_party_role_id,
        contact: 'ABC',
        currency_id: currency_id,
        currency: 'ABC',
        deal_type_id: deal_type_id,
        deal_type: 'ABC',
        incoterm_id: incoterm_id,
        incoterm: 'ABC',
        customer_payment_term_set_id: customer_payment_term_set_id,
        customer_payment_term_set: 'ABC',
        target_customer_party_role_id: target_customer_party_role_id,
        target_customer: 'ABC',
        exporter_party_role_id: exporter_party_role_id,
        exporter: 'ABC',
        packed_tm_group_id: target_market_group_id,
        packed_tm_group: 'ABC',
        final_receiver_party_role_id: final_receiver_party_role_id,
        final_receiver: 'ABC',
        marketing_org_party_role_id: marketing_org_party_role_id,
        marketing_org: 'ABC',
        allocated: false,
        shipping: false,
        shipped: false,
        completed: false,
        completed_at: '2010-01-01 12:00',
        customer_order_number: Faker::Lorem.unique.word,
        internal_order_number: 'ABC',
        order_number: 'ABC',
        remarks: 'ABC',
        contact_person_ids: [contact_party_role_id],
        pricing_per_kg: false,
        active: true
      }
    end

    def fake_order(overrides = {})
      Order.new(order_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= OrderInteractor.new(current_user, {}, {}, {})
    end
  end
end
