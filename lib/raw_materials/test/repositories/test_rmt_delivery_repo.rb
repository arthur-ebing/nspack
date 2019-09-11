# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module RawMaterialsApp
  class TestRmtDeliveryRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_rmt_deliveries
      assert_respond_to repo, :for_select_rmt_bins
    end

    def test_crud_calls
      test_crud_calls_for :rmt_deliveries, name: :rmt_delivery, wrapper: RmtDelivery
      test_crud_calls_for :rmt_bins, name: :rmt_bin, wrapper: RmtBin
    end

    private

    def repo
      RmtDeliveryRepo.new
    end
  end
end
