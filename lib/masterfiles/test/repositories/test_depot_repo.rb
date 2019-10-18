# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestDepotRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_depots
    end

    def test_crud_calls
      test_crud_calls_for :depots, name: :depot, wrapper: Depot
    end

    private

    def repo
      DepotRepo.new
    end
  end
end
