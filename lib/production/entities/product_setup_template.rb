# frozen_string_literal: true

module ProductionApp
  class ProductSetupTemplate < Dry::Struct
    attribute :id, Types::Integer
    attribute :template_name, Types::String
    attribute :description, Types::String
    attribute :cultivar_group_id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :packhouse_resource_id, Types::Integer
    attribute :production_line_id, Types::Integer
    attribute :season_group_id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :cultivar_group_code, Types::String
    attribute :cultivar_name, Types::String
    attribute :packhouse_resource_code, Types::String
    attribute :production_line_code, Types::String
    attribute :season_group_code, Types::String
    attribute :season_code, Types::String
    attribute? :active, Types::Bool
  end
end
