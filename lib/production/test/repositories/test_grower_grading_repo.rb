# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestGrowerGradingRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_grower_grading_rules
      assert_respond_to repo, :for_select_grower_grading_pools
    end

    def test_crud_calls
      test_crud_calls_for :grower_grading_rules, name: :grower_grading_rule, wrapper: GrowerGradingRule
      test_crud_calls_for :grower_grading_rule_items, name: :grower_grading_rule_item, wrapper: GrowerGradingRuleItem
      test_crud_calls_for :grower_grading_pools, name: :grower_grading_pool, wrapper: GrowerGradingPool
      test_crud_calls_for :grower_grading_cartons, name: :grower_grading_carton, wrapper: GrowerGradingCarton
      test_crud_calls_for :grower_grading_rebins, name: :grower_grading_rebin, wrapper: GrowerGradingRebin
    end

    private

    def repo
      GrowerGradingRepo.new
    end
  end
end
