# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestGovtInspectionSheetRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_govt_inspection_sheets
    end

    def test_crud_calls
      test_crud_calls_for :govt_inspection_sheets, name: :govt_inspection_sheet, wrapper: GovtInspectionSheet
    end

    private

    def repo
      GovtInspectionSheetRepo.new
    end
  end
end
