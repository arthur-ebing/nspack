# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestLoadVehicleRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_load_vehicles
    end

    def test_crud_calls
      test_crud_calls_for :load_vehicles, name: :load_vehicle, wrapper: LoadVehicle
    end

    private

    def repo
      LoadVehicleRepo.new
    end
  end
end
