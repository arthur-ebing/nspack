# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestQaStandardRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_qa_standards
    end

    def test_crud_calls
      test_crud_calls_for :qa_standards, name: :qa_standard, wrapper: QaStandard
    end

    private

    def repo
      QaStandardRepo.new
    end
  end
end
