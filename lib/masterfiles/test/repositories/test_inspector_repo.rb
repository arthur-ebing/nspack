# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestInspectorRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_inspectors
    end

    def test_crud_calls
      test_crud_calls_for :inspectors, name: :inspector, wrapper: Inspector
    end

    private

    def repo
      InspectorRepo.new
    end
  end
end
