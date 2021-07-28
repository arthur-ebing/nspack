# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestPalletHoldoverRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_pallet_holdovers
    end

    def test_crud_calls
      test_crud_calls_for :pallet_holdovers, name: :pallet_holdover, wrapper: PalletHoldover
    end

    private

    def repo
      PalletHoldoverRepo.new
    end
  end
end
