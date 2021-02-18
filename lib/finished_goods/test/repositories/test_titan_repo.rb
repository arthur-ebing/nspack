# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestTitanRepo < MiniTestWithHooks
    def test_crud_calls
      test_crud_calls_for :titan_requests, name: :titan_request
    end

    private

    def repo
      TitanRepo.new
    end
  end
end
