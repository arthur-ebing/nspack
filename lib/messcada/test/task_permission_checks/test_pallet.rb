# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MesscadaApp
  class TestPalletPermission < MiniTestWithHooks
    include Crossbeams::Responses
    include PalletFactory
    include MasterfilesApp::PackagingFactory
    include ProductionApp::ResourceFactory
    include MasterfilesApp::LocationFactory
    include MasterfilesApp::FruitFactory

    def repo
      @repo ||= BaseRepo.new
    end

    def test_exist
      pallet_id = create_pallet
      pallet_number = repo.get(:pallets, pallet_id, :pallet_number)

      res = TaskPermissionCheck::Pallet.call(:exists, pallet_id: pallet_id)
      assert res.success, 'Pallet should exist'

      res = TaskPermissionCheck::Pallet.call(:exists, pallet_id: pallet_id + 1)
      refute res.success, 'Pallet should not exist'

      res = TaskPermissionCheck::Pallet.call(:exists, pallet_number: pallet_number)
      assert res.success, 'Pallet should exist'

      res = TaskPermissionCheck::Pallet.call(:exists, pallet_number: 'fake_pallet_number')
      refute res.success, 'Pallet should not exist'

      res = TaskPermissionCheck::Pallet.call(:exists, pallet_ids: [pallet_id])
      assert res.success, 'Pallet should exist'

      res = TaskPermissionCheck::Pallet.call(:exists, pallet_numbers: [pallet_number])
      assert res.success, 'Pallet should exist'
    end
  end
end
