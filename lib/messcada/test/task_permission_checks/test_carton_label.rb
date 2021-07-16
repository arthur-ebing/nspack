# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MesscadaApp
  class TestCartonLabelPermission < MiniTestWithHooks
    include Crossbeams::Responses
    include CartonFactory
    include ProductionApp::ProductionRunFactory
    include MasterfilesApp::FarmFactory
    include MasterfilesApp::PartyFactory
    include ProductionApp::ResourceFactory
    include MasterfilesApp::LocationFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::CultivarFactory
    include ProductionApp::ProductSetupFactory
    include MasterfilesApp::TargetMarketFactory
    include MasterfilesApp::FruitFactory
    include MasterfilesApp::GeneralFactory
    include MasterfilesApp::MarketingFactory
    include MasterfilesApp::PackagingFactory
    include RawMaterialsApp::RmtBinFactory
    include MasterfilesApp::HRFactory

    def repo
      @repo ||= BaseRepo.new
    end

    def test_exist
      carton_label_id = create_carton_label

      res = TaskPermissionCheck::CartonLabel.call(:exists, carton_label_id: carton_label_id)
      assert res.success, 'Carton Label should exist'

      res = TaskPermissionCheck::CartonLabel.call(:exists, carton_label_id: carton_label_id - 1)
      refute res.success, 'Carton Label should not exist'

      res = TaskPermissionCheck::CartonLabel.call(:exists, carton_label_ids: [carton_label_id])
      assert res.success, 'Carton Label should exist'
    end
  end
end
