# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestGovtInspectionPalletApiResultPermission < Minitest::Test
    include Crossbeams::Responses
    include GovtInspectionFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        passed: false,
        failure_reasons: {},
        govt_inspection_pallet_id: 1,
        govt_inspection_api_result_id: 1,
        active: true
      }
      FinishedGoodsApp::GovtInspectionPalletApiResult.new(base_attrs.merge(attrs))
    end

    def test_create
      res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionPalletApiResult.call(:create)
      assert res.success, 'Should always be able to create a govt_inspection_pallet_api_result'
    end

    def test_edit
      FinishedGoodsApp::GovtInspectionRepo.any_instance.stubs(:find_govt_inspection_pallet_api_result).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionPalletApiResult.call(:edit, 1)
      assert res.success, 'Should be able to edit a govt_inspection_pallet_api_result'
    end

    def test_delete
      FinishedGoodsApp::GovtInspectionRepo.any_instance.stubs(:find_govt_inspection_pallet_api_result).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionPalletApiResult.call(:delete, 1)
      assert res.success, 'Should be able to delete a govt_inspection_pallet_api_result'
    end
  end
end
