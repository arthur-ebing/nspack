# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestOrchardTestRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_orchard_test_types
    end

    def test_crud_calls
      test_crud_calls_for :orchard_test_types, name: :orchard_test_type, wrapper: OrchardTestType
    end

    private

    def repo
      OrchardTestRepo.new
    end
  end
end
