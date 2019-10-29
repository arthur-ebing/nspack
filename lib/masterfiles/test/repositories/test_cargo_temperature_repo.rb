# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestCargoTemperatureRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_cargo_temperatures
    end

    def test_crud_calls
      test_crud_calls_for :cargo_temperatures, name: :cargo_temperature, wrapper: CargoTemperature
    end

    private

    def repo
      CargoTemperatureRepo.new
    end
  end
end
