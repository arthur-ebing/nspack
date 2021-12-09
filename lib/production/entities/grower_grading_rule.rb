# frozen_string_literal: true

module ProductionApp
  class GrowerGradingRule < Dry::Struct
    attribute :id, Types::Integer
    attribute :rule_name, Types::String
    attribute :description, Types::String
    attribute :file_name, Types::String
    attribute :packhouse_resource_id, Types::Integer
    attribute :line_resource_id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :cultivar_group_id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :rebin_rule, Types::Bool
    attribute :created_by, Types::String
    attribute :updated_by, Types::String
    attribute? :active, Types::Bool
  end

  class GrowerGradingRuleFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :rule_name, Types::String
    attribute :description, Types::String
    attribute :file_name, Types::String
    attribute :packhouse_resource_id, Types::Integer
    attribute :line_resource_id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :cultivar_group_id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :rebin_rule, Types::Bool
    attribute :created_by, Types::String
    attribute :updated_by, Types::String
    attribute? :active, Types::Bool
    attribute :packhouse_resource_code, Types::String
    attribute :line_resource_code, Types::String
    attribute :season_code, Types::String
    attribute :cultivar_group_code, Types::String
    attribute :cultivar_name, Types::String
  end
end
