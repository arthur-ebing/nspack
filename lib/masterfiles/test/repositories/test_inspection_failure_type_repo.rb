# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestInspectionFailureTypeRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_inspection_failure_types
    end

    def test_crud_calls
      test_crud_calls_for :inspection_failure_types, name: :inspection_failure_type, wrapper: InspectionFailureType
    end

    private

    def repo
      InspectionFailureTypeRepo.new
    end
  end
end
