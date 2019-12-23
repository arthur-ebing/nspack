# frozen_string_literal: true

module MasterfilesApp
  class Port < Dry::Struct
    attribute :id, Types::Integer
    attribute :port_type_ids, Types::Array
    attribute :voyage_type_ids, Types::Array
    attribute :city_id, Types::Integer
    attribute :port_code, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end
  class PortFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :port_code, Types::String
    attribute :description, Types::String
    attribute :port_type_ids, Types::Array
    attribute :voyage_type_ids, Types::Array
    attribute :city_id, Types::Integer
    attribute :city_name, Types::String
    attribute :port_type_codes, Types::String
    attribute :voyage_type_codes, Types::String
    attribute? :active, Types::Bool
  end
end
