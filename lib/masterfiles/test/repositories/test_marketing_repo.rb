# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestMarketingRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_marks
    end

    def test_crud_calls
      test_crud_calls_for :marks, name: :mark, wrapper: Mark
    end

    private

    def repo
      MarketingRepo.new
    end
  end
end
