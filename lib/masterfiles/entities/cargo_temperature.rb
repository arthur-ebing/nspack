# frozen_string_literal: true

module MasterfilesApp
  class CargoTemperature < Dry::Struct
    attribute :id, Types::Integer
    attribute :temperature_code, Types::String
    attribute :description, Types::String
    attribute :set_point_temperature, Types::Decimal
    attribute :load_temperature, Types::Decimal
    attribute? :active, Types::Bool
  end
end
