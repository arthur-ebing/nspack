# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestShipLoad < MiniTestWithHooks
    include FinishedGoodsApp::OrderFactory
    include MasterfilesApp::FinanceFactory

    include FinishedGoodsApp::LoadFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::DepotFactory
    include MasterfilesApp::VesselFactory
    include MasterfilesApp::PortFactory
    include FinishedGoodsApp::VoyageFactory

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

    def repo
      @repo ||= BaseRepo.new
    end

    def test_unship_load_and_order
      load_id = create_load(allocated: true, loaded: true, shipped: true)
      create_load_vehicle(load_id: load_id)

      order_id = create_order(shipped: true)
      create_orders_loads(load_id: load_id, order_id: order_id)
      order_item_id = create_order_item(order_id: order_id, carton_quantity: 10)

      location_id = create_location(force_create: true)
      pallet_id = create_pallet(load_id: load_id, location_id: location_id, shipped: true)
      create_pallet_sequence(pallet_id: pallet_id, order_item_id: order_item_id, carton_quantity: 10)

      location_type_id = create_location_type(location_type_code: 'SITE')
      create_location(location_type_id: location_type_id)

      res = UnshipLoad.call(load_id, current_user)
      assert res.success, 'Should unship load'
      assert !repo.get(:loads, load_id, :shipped), 'Should unship Load'
      assert !repo.get(:orders, order_id, :shipped), 'Should unship Order'
    end
  end
end
