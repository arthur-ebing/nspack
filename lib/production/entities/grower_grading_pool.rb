# frozen_string_literal: true

module ProductionApp
  class GrowerGradingPool < Dry::Struct
    attribute :id, Types::Integer
    attribute :grower_grading_rule_id, Types::Integer
    attribute :pool_name, Types::String
    attribute :description, Types::String
    attribute :production_run_id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :cultivar_group_id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :commodity_id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :inspection_type_id, Types::Integer
    attribute :bin_quantity, Types::Integer
    attribute :gross_weight, Types::Decimal
    attribute :nett_weight, Types::Decimal
    attribute :pro_rata_factor, Types::Decimal
    attribute :legacy_data, Types::Hash
    attribute :completed, Types::Bool
    attribute :rule_applied, Types::Bool
    attribute :created_by, Types::String
    attribute :updated_by, Types::String
    attribute :rule_applied_by, Types::String
    attribute :rule_applied_at, Types::DateTime
    attribute? :active, Types::Bool
  end

  class GrowerGradingPoolFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :grower_grading_rule_id, Types::Integer
    attribute :pool_name, Types::String
    attribute :description, Types::String
    attribute :production_run_id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :cultivar_group_id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :commodity_id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :inspection_type_id, Types::Integer
    attribute :bin_quantity, Types::Integer
    attribute :gross_weight, Types::Decimal
    attribute :nett_weight, Types::Decimal
    attribute :pro_rata_factor, Types::Decimal
    attribute :legacy_data, Types::Hash
    attribute :completed, Types::Bool
    attribute :rule_applied, Types::Bool
    attribute :created_by, Types::String
    attribute :updated_by, Types::String
    attribute :rule_applied_by, Types::String
    attribute :rule_applied_at, Types::DateTime
    attribute? :active, Types::Bool
    attribute :production_run_code, Types::String
    attribute :season_code, Types::String
    attribute :cultivar_group_code, Types::String
    attribute :cultivar_name, Types::String
    attribute :commodity_code, Types::String
    attribute :farm_code, Types::String
    attribute :inspection_type_code, Types::String
  end
end
