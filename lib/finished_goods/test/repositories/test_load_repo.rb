# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestLoadRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_loads
    end

    def test_crud_calls
      test_crud_calls_for :loads, name: :load, wrapper: Load
    end

    private

    def repo
      LoadRepo.new
    end
  end
end
