# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module QualityApp
  class TestOrchardTestRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_orchard_test_types
      assert_respond_to repo, :for_select_orchard_test_results
    end

    def test_crud_calls
      test_crud_calls_for :orchard_test_types, name: :orchard_test_type, wrapper: OrchardTestType
      test_crud_calls_for :orchard_test_results, name: :orchard_test_result, wrapper: OrchardTestResult
    end

    private

    def repo
      OrchardTestRepo.new
    end
  end
end
