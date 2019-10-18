# frozen_string_literal: true

module MasterfilesApp
  class Port < Dry::Struct
    attribute :id, Types::Integer
    attribute :port_type_id, Types::Integer
    attribute :voyage_type_id, Types::Integer
    attribute :city_id, Types::Integer
    attribute :port_code, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end
  class PortFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :port_code, Types::String
    attribute :port_type_id, Types::Integer
    attribute :voyage_type_id, Types::Integer
    attribute :city_id, Types::Integer
    attribute :city_name, Types::String
    attribute :description, Types::String
    attribute :port_type_code, Types::String
    attribute :voyage_type_code, Types::String
    attribute? :active, Types::Bool
  end
end
