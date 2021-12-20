# frozen_string_literal: true

module ProductionApp
  class GrowerGradingRebin < Dry::Struct
    attribute :id, Types::Integer
    attribute :grower_grading_pool_id, Types::Integer
    attribute :grower_grading_rule_item_id, Types::Integer
    attribute :rmt_class_id, Types::Integer
    attribute :rmt_size_id, Types::Integer
    attribute :changes_made, Types::Hash
    attribute :rebins_quantity, Types::Integer
    attribute :gross_weight, Types::Decimal
    attribute :nett_weight, Types::Decimal
    attribute :completed, Types::Bool
    attribute :pallet_rebin, Types::Bool
    attribute :updated_by, Types::String
    attribute? :active, Types::Bool
  end

  class GrowerGradingRebinFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :grower_grading_pool_id, Types::Integer
    attribute :grower_grading_rule_item_id, Types::Integer
    attribute :rmt_class_id, Types::Integer
    attribute :rmt_size_id, Types::Integer
    attribute :changes_made, Types::Hash
    attribute :rebins_quantity, Types::Integer
    attribute :gross_weight, Types::Decimal
    attribute :nett_weight, Types::Decimal
    attribute :completed, Types::Bool
    attribute :pallet_rebin, Types::Bool
    attribute :updated_by, Types::String
    attribute? :active, Types::Bool
    attribute :pool_name, Types::String
    attribute :grading_rebin_code, Types::String
    attribute :rmt_class_code, Types::String
    attribute :rmt_size_code, Types::String
  end
end
