# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module RawMaterialsApp
  class TestPresortGrowerGradingRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_presort_grower_grading_pools
      assert_respond_to repo, :for_select_presort_grower_grading_bins
    end

    def test_crud_calls
      test_crud_calls_for :presort_grower_grading_pools, name: :presort_grower_grading_pool, wrapper: PresortGrowerGradingPool
      test_crud_calls_for :presort_grower_grading_bins, name: :presort_grower_grading_bin, wrapper: PresortGrowerGradingBin
    end

    private

    def repo
      PresortGrowerGradingRepo.new
    end
  end
end
