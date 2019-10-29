# frozen_string_literal: true

module MasterfilesApp
  class CargoTemperatureRepo < BaseRepo
    build_for_select :cargo_temperatures,
                     label: :temperature_code,
                     value: :id,
                     order_by: :temperature_code
    build_inactive_select :cargo_temperatures,
                          label: :temperature_code,
                          value: :id,
                          order_by: :temperature_code

    crud_calls_for :cargo_temperatures, name: :cargo_temperature, wrapper: CargoTemperature
  end
end
