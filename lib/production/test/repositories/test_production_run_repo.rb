# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestProductionRunRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_production_runs
    end

    def test_crud_calls
      test_crud_calls_for :production_runs, name: :production_run, wrapper: ProductionRun
    end

    private

    def repo
      ProductionRunRepo.new
    end
  end
end
