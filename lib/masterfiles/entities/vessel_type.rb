# frozen_string_literal: true

module MasterfilesApp
  class VesselType < Dry::Struct
    attribute :id, Types::Integer
    attribute :voyage_type_id, Types::Integer
    attribute :vessel_type_code, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end

  class VesselTypeFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :voyage_type_id, Types::Integer
    attribute :vessel_type_code, Types::String
    attribute :description, Types::String
    attribute :voyage_type_code, Types::String
    attribute? :active, Types::Bool
  end
end
