# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestVoyageRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_voyages
    end

    def test_crud_calls
      test_crud_calls_for :voyages, name: :voyage, wrapper: Voyage
    end

    private

    def repo
      VoyageRepo.new
    end
  end
end
