# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestGovtInspectionPalletPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        pallet_id: 1,
        pallet_number: '123',
        govt_inspection_sheet_id: 1,
        passed: false,
        completed: false,
        inspected: false,
        failure_reason: 'test',
        description: 'test',
        main_factor: 'test',
        secondary_factor: 'test',
        sheet_inspected: false,
        nett_weight: 1.1,
        gross_weight: 1.1,
        carton_quantity: 1,
        inspected_at: '2010-01-01 12:00',
        failure_reason_id: 1,
        failure_remarks: Faker::Lorem.unique.word,
        marketing_varieties: %w[A B C],
        packed_tm_groups: %w[A B C],
        pallet_base: 'A',
        active: true
      }
      FinishedGoodsApp::GovtInspectionPallet.new(base_attrs.merge(attrs))
    end

    def test_create
      res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionPallet.call(:create)
      assert res.success, 'Should always be able to create a govt_inspection_pallet'
    end

    def test_edit
      FinishedGoodsApp::GovtInspectionRepo.any_instance.stubs(:find_govt_inspection_pallet).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionPallet.call(:edit, 1)
      assert res.success, 'Should be able to edit a govt_inspection_pallet'
    end

    def test_delete
      FinishedGoodsApp::GovtInspectionRepo.any_instance.stubs(:find_govt_inspection_pallet).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionPallet.call(:delete, 1)
      assert res.success, 'Should be able to delete a govt_inspection_pallet'
    end
  end
end
