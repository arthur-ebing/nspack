# frozen_string_literal: true

module RawMaterialsApp
  class Location < Dry::Struct
    attribute :id, Types::Integer
    attribute :location_long_code, Types::String
    attribute :current_status, Types::String
  end
end
