# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestGovtInspectionApiResultRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_govt_inspection_api_results
    end

    def test_crud_calls
      test_crud_calls_for :govt_inspection_api_results, name: :govt_inspection_api_result, wrapper: GovtInspectionApiResult
    end

    private

    def repo
      GovtInspectionApiResultRepo.new
    end
  end
end
