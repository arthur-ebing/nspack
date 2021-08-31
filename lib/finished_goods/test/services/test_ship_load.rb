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
    include FinishedGoodsApp::PalletHoldoverFactory

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

    def test_ship_load_and_order
      load_id = create_load(allocated: true, loaded: true)
      create_load_vehicle(load_id: load_id)

      order_id = create_order
      create_orders_loads(load_id: load_id, order_id: order_id)
      order_item_id = create_order_item(order_id: order_id, carton_quantity: 10)

      location_id = create_location(force_create: true)
      pallet_id = create_pallet(load_id: load_id, location_id: location_id)
      create_pallet_sequence(pallet_id: pallet_id, order_item_id: order_item_id, carton_quantity: 10)

      res = ShipLoad.call(load_id, current_user)
      assert res.success, res.message
      assert repo.get(:pallets, pallet_id, :shipped), 'Should Ship Pallet'
      assert repo.get(:loads, load_id, :shipped), 'Should Ship Load'
      assert repo.get(:orders, order_id, :shipped), 'Should Ship Order'
    end

    def test_ship_order_fail
      load_id = create_load(allocated: true, loaded: true)
      create_load_vehicle(load_id: load_id)

      order_id = create_order
      create_orders_loads(load_id: load_id, order_id: order_id)
      order_item_id = create_order_item(order_id: order_id, carton_quantity: 9)

      location_id = create_location(force_create: true)
      pallet_id = create_pallet(load_id: load_id, location_id: location_id)
      create_pallet_sequence(pallet_id: pallet_id, order_item_id: order_item_id, carton_quantity: 10)

      res = ShipLoad.call(load_id, current_user)
      assert res.success, res.message
      assert repo.get(:pallets, pallet_id, :shipped), 'Should Ship Pallet'
      assert repo.get(:loads, load_id, :shipped), 'Should ship Load'
      refute repo.get(:orders, order_id, :shipped), 'Should not ship Order'
    end

    def test_ship_load_fail
      load_id = create_load(allocated: true)

      location_id = create_location(force_create: true)
      pallet_id = create_pallet(load_id: load_id, location_id: location_id)
      create_pallet_sequence(pallet_id: pallet_id)

      res = ShipLoad.call(load_id, current_user)
      refute res.success, res.message
      refute repo.get(:pallets, pallet_id, :shipped), 'Pallet should not be shipped'
      refute repo.get(:loads, load_id, :shipped), 'Load should not be shipped'
    end

    def test_ship_load_with_holdover_fail
      load_id = create_load(allocated: true)

      location_id = create_location(force_create: true)
      pallet_id = create_pallet(load_id: load_id, location_id: location_id)
      create_pallet_sequence(pallet_id: pallet_id)
      carton_quantity = repo.get(:pallets, pallet_id, :carton_quantity)
      create_pallet_holdover(pallet_id: pallet_id, holdover_quantity: carton_quantity + 1)

      res = ShipLoad.call(load_id, current_user)
      refute res.success, res.message
      refute repo.get(:loads, load_id, :shipped), 'Load should not be shipped'
    end

    def test_ship_load_with_holdover_pass
      load_id = create_load(allocated: true, loaded: true)
      create_load_vehicle(load_id: load_id)

      location_id = create_location(force_create: true)
      pallet_id = create_pallet(load_id: load_id, location_id: location_id)
      create_pallet_sequence(pallet_id: pallet_id)

      carton_quantity = repo.get(:pallets, pallet_id, :carton_quantity)
      create_pallet_holdover(pallet_id: pallet_id, holdover_quantity: carton_quantity)

      res = ShipLoad.call(load_id, current_user)
      assert res.success, res.message
      assert repo.get(:loads, load_id, :shipped), 'Load should be shipped'
    end
  end
end
