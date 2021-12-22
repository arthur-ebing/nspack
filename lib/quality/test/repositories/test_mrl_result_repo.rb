# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module QualityApp
  class TestMrlResultRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_mrl_results
    end

    def test_crud_calls
      test_crud_calls_for :mrl_results, name: :mrl_result, wrapper: MrlResult
    end

    private

    def repo
      MrlResultRepo.new
    end
  end
end
