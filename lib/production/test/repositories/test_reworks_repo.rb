# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestReworksRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_reworks_runs
    end

    def test_crud_calls
      test_crud_calls_for :reworks_runs, name: :reworks_run, wrapper: ReworksRun
    end

    private

    def repo
      ReworksRepo.new
    end
  end
end
