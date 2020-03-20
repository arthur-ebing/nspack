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

    def for_select_cargo_temperatures
      query = <<~SQL
        SELECT temperature_code||' ('||set_point_temperature||')' AS code, id FROM cargo_temperatures
      SQL
      DB[query].select_map(%i[code id])
    end

    def cargo_temperature_id_for(code)
      return nil if code.nil_or_empty?

      DB[:cargo_temperatures].where(temperature_code: code).get(:id)
    end
  end
end
