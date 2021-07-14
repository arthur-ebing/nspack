# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MesscadaApp
  class TestNewPalletSequenceObject < MiniTestWithHooks
    include CartonFactory
    include ProductionApp::ProductionRunFactory
    include MasterfilesApp::FarmFactory
    include MasterfilesApp::PartyFactory
    include ProductionApp::ResourceFactory
    include MasterfilesApp::LocationFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::PackagingFactory
    include MasterfilesApp::FruitFactory
    include MasterfilesApp::TargetMarketFactory
    include MasterfilesApp::MarketingFactory
    include MasterfilesApp::GeneralFactory
    include MasterfilesApp::HRFactory
    include ProductionApp::ResourceFactory
    include ProductionApp::ProductionRunFactory
    include ProductionApp::ProductSetupFactory
    include RawMaterialsApp::RmtBinFactory
    include MasterfilesApp::CommodityFactory

    def test_create_new_pallet_sequence_object
      carton_id = create_carton

      res = MesscadaApp::NewPalletSequenceObject.call(current_user.user_name, carton_id, 1)
      assert res.success, 'success'
    end

    def test_create_new_pallet_sequence_object_fail
      res = MesscadaApp::NewPalletSequenceObject.call(current_user.user_name, nil, 1)
      refute res.success, 'Carton not found.'
    end
  end
end
