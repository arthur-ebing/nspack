# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestVoyagePortRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_voyage_ports
    end

    def test_crud_calls
      test_crud_calls_for :voyage_ports, name: :voyage_port, wrapper: VoyagePort
    end

    private

    def repo
      VoyagePortRepo.new
    end
  end
end
