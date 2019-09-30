# frozen_string_literal: true

module MasterfilesApp
  class VehicleType < Dry::Struct
    attribute :id, Types::Integer
    attribute :vehicle_type_code, Types::String
    attribute :description, Types::String
    attribute :has_container, Types::Bool
    attribute? :active, Types::Bool
  end
end
