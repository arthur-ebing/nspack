# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestLoadVoyageRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_load_voyages
    end

    def test_crud_calls
      test_crud_calls_for :load_voyages, name: :load_voyage, wrapper: LoadVoyage
    end

    private

    def repo
      LoadVoyageRepo.new
    end
  end
end
