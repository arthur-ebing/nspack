# frozen_string_literal: true

module MasterfilesApp
  class Depot < Dry::Struct
    attribute :id, Types::Integer
    attribute :city_id, Types::Integer
    attribute :depot_code, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end

  class DepotFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :city_id, Types::Integer
    attribute :depot_code, Types::String
    attribute :description, Types::String
    attribute :city_name, Types::String
    attribute? :active, Types::Bool
  end
end
