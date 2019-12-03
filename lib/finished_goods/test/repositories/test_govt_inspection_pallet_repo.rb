# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestGovtInspectionPalletRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_govt_inspection_pallets
    end

    def test_crud_calls
      test_crud_calls_for :govt_inspection_pallets, name: :govt_inspection_pallet, wrapper: GovtInspectionPallet
    end

    private

    def repo
      GovtInspectionPalletRepo.new
    end
  end
end
