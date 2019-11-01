# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestLoadContainerRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_load_containers
    end

    def test_crud_calls
      test_crud_calls_for :load_containers, name: :load_container, wrapper: LoadContainer
    end

    private

    def repo
      LoadContainerRepo.new
    end
  end
end
