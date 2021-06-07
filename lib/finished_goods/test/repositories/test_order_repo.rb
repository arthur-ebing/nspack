# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestOrderRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_orders
      assert_respond_to repo, :for_select_order_items
    end

    def test_crud_calls
      test_crud_calls_for :orders, name: :order, wrapper: Order
      test_crud_calls_for :order_items, name: :order_item, wrapper: OrderItem
    end

    private

    def repo
      OrderRepo.new
    end
  end
end
