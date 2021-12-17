# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module QualityApp
  class TestQcRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_qc_samples
    end

    def test_crud_calls
      test_crud_calls_for :qc_samples, name: :qc_sample, wrapper: QcSample
    end

    private

    def repo
      QcRepo.new
    end
  end
end
