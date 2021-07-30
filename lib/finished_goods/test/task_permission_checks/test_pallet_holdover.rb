# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestPalletHoldoverPermission < Minitest::Test
    include Crossbeams::Responses
    include PalletHoldoverFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        pallet_id: 1,
        pallet_number: '1234567',
        holdover_quantity: 1,
        buildup_remarks: Faker::Lorem.unique.word
      }
      FinishedGoodsApp::PalletHoldover.new(base_attrs.merge(attrs))
    end

    def test_create
      res = FinishedGoodsApp::TaskPermissionCheck::PalletHoldover.call(:create)
      assert res.success, 'Should always be able to create a pallet_holdover'
    end

    def test_edit
      FinishedGoodsApp::PalletHoldoverRepo.any_instance.stubs(:find_pallet_holdover).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::PalletHoldover.call(:edit, 1)
      assert res.success, 'Should be able to edit a pallet_holdover'
    end

    def test_delete
      FinishedGoodsApp::PalletHoldoverRepo.any_instance.stubs(:find_pallet_holdover).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::PalletHoldover.call(:delete, 1)
      assert res.success, 'Should be able to delete a pallet_holdover'
    end
  end
end
