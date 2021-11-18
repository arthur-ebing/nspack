# frozen_string_literal: true

module MasterfilesApp
  class ProductionRegion < Dry::Struct
    attribute :id, Types::Integer
    attribute :production_region_code, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
    attribute :inspection_region, Types::String
  end
end
