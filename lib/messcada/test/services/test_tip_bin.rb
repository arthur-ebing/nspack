# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MesscadaApp
  class TestTipBin < MiniTestWithHooks
    include Crossbeams::Responses
    include CartonFactory
    include PalletFactory
    include ProductionApp::ProductionRunFactory
    include ProductionApp::ResourceFactory
    include ProductionApp::ProductSetupFactory
    include MasterfilesApp::FarmFactory
    include MasterfilesApp::FruitFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::TargetMarketFactory
    include MasterfilesApp::GeneralFactory
    include MasterfilesApp::MarketingFactory
    include MasterfilesApp::PackagingFactory
    include MasterfilesApp::HRFactory
    include MasterfilesApp::LocationFactory
    include MasterfilesApp::DepotFactory
    include MasterfilesApp::VesselFactory
    include MasterfilesApp::PortFactory
    include MasterfilesApp::QualityFactory
    include MasterfilesApp::RmtContainerFactory
    include RawMaterialsApp::RmtBinFactory
    include RawMaterialsApp::RmtDeliveryFactory
    include FinishedGoodsApp::LoadFactory
    include FinishedGoodsApp::VoyageFactory

    def test_standard_failures
      AppConst::TEST_SETTINGS.client_code = 'hl'
      refute AppConst::CR_PROD.kromco_rmt_integration?
      refute AppConst::CR_RMT.convert_carton_to_rebins?

      # 1. bin does not exist (Normally this would be caught in CanTipBin anyway - test just here in case logic changes in future)
      run_id = create_production_run
      run_res = success_response('ok', run_id)
      TipBin.any_instance.stubs(:active_run_for_device).returns(run_res)
      CanTipBin.any_instance.stubs(:call).returns(ok_response)
      res = MesscadaApp::TipBin.call(bin_number: '11', device: 'CLM-01')
      refute res.success, "Should have failed with bin not found - #{res.message}"

      # 2. Handle a failure in MoveStock service
      bin_id = create_rmt_bin(bin_asset_number: '123456',
                              tipped_asset_number: nil,
                              exit_ref: nil,
                              bin_tipped_date_time: nil,
                              scrapped: false)
      bin = DB[:rmt_bins].where(id: bin_id).first
      CanTipBin.any_instance.stubs(:call).returns(ok_response)
      FinishedGoodsApp::MoveStock.any_instance.stubs(:call).returns(bad_response(message: 'NO'))
      res = MesscadaApp::TipBin.call(bin_number: bin[:bin_asset_number], device: 'CLM-01')
      refute res.success, "Should have failed with bin already tipped - #{res.message}"
      assert_equal 'NO', res.message, "Should have failed with expected message, not #{res.message}"
    ensure
      AppConst::TEST_SETTINGS.client_code = AppConst::TEST_SETTINGS.boot_client_code
    end

    def test_basic_ok_tip
      AppConst::TEST_SETTINGS.client_code = 'hl'
      bin_id = create_rmt_bin(bin_asset_number: '123456',
                              tipped_asset_number: nil,
                              exit_ref: nil,
                              bin_tipped_date_time: nil,
                              scrapped: false)
      run_id = create_production_run
      bin = DB[:rmt_bins].where(id: bin_id).first
      run_res = success_response('ok', run_id)
      plant_resource = DB[:plant_resources].where(id: create_plant_resource(plant_resource_type_id: create_plant_resource_type(plant_resource_type_code: 'LINE'))).first
      CanTipBin.any_instance.stubs(:call).returns(ok_response)
      FinishedGoodsApp::MoveStock.any_instance.stubs(:call).returns(ok_response)
      ProductionApp::ResourceRepo.stubs(:find_plant_resource).returns(plant_resource)
      TipBin.any_instance.stubs(:active_run_for_device).returns(run_res)
      res = MesscadaApp::TipBin.call(bin_number: bin[:bin_asset_number], device: 'CLM-01')
      assert res.success, "Should have tipped the bin - #{res.message}"
      upd_bin = DB[:rmt_bins].where(id: bin_id).first
      assert_equal 'TIPPED', upd_bin[:exit_ref]
      assert_equal run_id, upd_bin[:production_run_tipped_id]
      assert upd_bin[:bin_tipped]
      assert_nil upd_bin[:bin_asset_number]
      # TODO: make AppConst::USE_PERMANENT_RMT_BIN_BARCODES a client rule and test here for bin_asset
    ensure
      AppConst::TEST_SETTINGS.client_code = AppConst::TEST_SETTINGS.boot_client_code
    end
  end
end
