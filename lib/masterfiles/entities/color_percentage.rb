# frozen_string_literal: true

module MasterfilesApp
  class ColorPercentage < Dry::Struct
    attribute :id, Types::Integer
    attribute :commodity_id, Types::Integer
    attribute :color_percentage, Types::Integer
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end

  class ColorPercentageFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :commodity_id, Types::Integer
    attribute :color_percentage, Types::Integer
    attribute :description, Types::String
    attribute? :active, Types::Bool
    attribute :commodity_code, Types::String
  end
end
