# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestGovtInspectionRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_govt_inspection_sheets
      assert_respond_to repo, :for_select_govt_inspection_pallets
      assert_respond_to repo, :for_select_govt_inspection_pallet_api_results
      assert_respond_to repo, :for_select_govt_inspection_api_results
    end

    def test_crud_calls
      test_crud_calls_for :govt_inspection_sheets, name: :govt_inspection_sheet, wrapper: GovtInspectionSheet
      test_crud_calls_for :govt_inspection_pallets, name: :govt_inspection_pallet, wrapper: GovtInspectionPallet
      test_crud_calls_for :govt_inspection_pallet_api_results, name: :govt_inspection_pallet_api_result, wrapper: GovtInspectionPalletApiResult
      test_crud_calls_for :govt_inspection_api_results, name: :govt_inspection_api_result, wrapper: GovtInspectionApiResult
    end

    private

    def repo
      GovtInspectionRepo.new
    end
  end
end
