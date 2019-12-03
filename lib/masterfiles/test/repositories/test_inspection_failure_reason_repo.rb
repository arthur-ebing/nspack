# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestInspectionFailureReasonRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_inspection_failure_reasons
    end

    def test_crud_calls
      test_crud_calls_for :inspection_failure_reasons, name: :inspection_failure_reason, wrapper: InspectionFailureReason
    end

    private

    def repo
      InspectionFailureReasonRepo.new
    end
  end
end
