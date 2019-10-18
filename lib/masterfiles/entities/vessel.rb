# frozen_string_literal: true

module MasterfilesApp
  class Vessel < Dry::Struct
    attribute :id, Types::Integer
    attribute :vessel_type_id, Types::Integer
    attribute :vessel_code, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end

  class VesselFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :vessel_type_id, Types::Integer
    attribute :vessel_code, Types::String
    attribute :description, Types::String
    attribute :vessel_type_code, Types::String
    attribute :voyage_type_code, Types::String
    attribute? :active, Types::Bool
  end
end
