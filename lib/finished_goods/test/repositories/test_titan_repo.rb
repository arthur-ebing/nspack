# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestTitanRepo < MiniTestWithHooks
    def test_crud_calls
      test_crud_calls_for :titan_requests, name: :titan_request
      assert_respond_to repo, :find_pallet_for_titan
      assert_respond_to repo, :find_pallet_sequence_for_titan
      assert_respond_to repo, :find_titan_addendum
      assert_respond_to repo, :find_titan_inspection
    end

    private

    def repo
      TitanRepo.new
    end
  end
end
