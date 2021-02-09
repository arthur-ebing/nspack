# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestInspectionRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_inspections
    end

    def test_crud_calls
      test_crud_calls_for :inspections, name: :inspection, wrapper: Inspection
    end

    private

    def repo
      InspectionRepo.new
    end
  end
end
