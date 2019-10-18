# frozen_string_literal: true

module FinishedGoodsApp
  class Voyage < Dry::Struct
    attribute :id, Types::Integer
    attribute :vessel_id, Types::Integer
    attribute :voyage_type_id, Types::Integer
    attribute :voyage_number, Types::String
    attribute :voyage_code, Types::String
    attribute :year, Types::Integer
    attribute :completed, Types::Bool
    attribute :completed_at, Types::DateTime
    attribute? :active, Types::Bool
  end

  class VoyageFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :vessel_id, Types::Integer
    attribute :voyage_type_id, Types::Integer
    attribute :voyage_number, Types::String
    attribute :voyage_code, Types::String
    attribute :year, Types::Integer
    attribute :completed, Types::Bool
    attribute :completed_at, Types::DateTime
    attribute :voyage_type_code, Types::String
    attribute :vessel_code, Types::String
    attribute? :active, Types::Bool
  end
end
