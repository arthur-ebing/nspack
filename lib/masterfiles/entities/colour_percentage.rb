# frozen_string_literal: true

module MasterfilesApp
  class ColourPercentage < Dry::Struct
    attribute :id, Types::Integer
    attribute :commodity_id, Types::Integer
    attribute :colour_percentage, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end

  class ColourPercentageFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :commodity_id, Types::Integer
    attribute :colour_percentage, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
    attribute :commodity_code, Types::String
  end
end
