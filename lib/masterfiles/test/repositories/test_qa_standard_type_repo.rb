# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestQaStandardTypeRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_qa_standard_types
    end

    def test_crud_calls
      test_crud_calls_for :qa_standard_types, name: :qa_standard_type, wrapper: QaStandardType
    end

    private

    def repo
      QaStandardTypeRepo.new
    end
  end
end
