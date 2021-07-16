# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MesscadaApp
  class TestPalletSequencePermission < MiniTestWithHooks
    include Crossbeams::Responses
    include PalletFactory
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

    def test_exist
      pallet_sequence_id = create_pallet_sequence

      res = TaskPermissionCheck::PalletSequence.call(:exists, pallet_sequence_id: pallet_sequence_id)
      assert res.success, 'Pallet Sequence should exist'

      res = TaskPermissionCheck::PalletSequence.call(:exists, pallet_sequence_id: pallet_sequence_id - 1)
      refute res.success, 'Pallet Sequence should not exist'

      res = TaskPermissionCheck::PalletSequence.call(:exists, pallet_sequence_ids: [pallet_sequence_id])
      assert res.success, 'Pallet Sequence should exist'
    end
  end
end
