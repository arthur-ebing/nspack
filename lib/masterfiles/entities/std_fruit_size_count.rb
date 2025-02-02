# frozen_string_literal: true

module MasterfilesApp
  class StdFruitSizeCount < Dry::Struct
    attribute :id, Types::Integer
    attribute :commodity_id, Types::Integer
    attribute :commodity_code, Types::String
    attribute :uom_id, Types::Integer
    attribute :uom_code, Types::String
    attribute :size_count_description, Types::String
    attribute :marketing_size_range_mm, Types::String
    attribute :marketing_weight_range, Types::String
    attribute :size_count_interval_group, Types::String
    attribute :size_count_value, Types::Integer
    attribute :minimum_size_mm, Types::Integer
    attribute :maximum_size_mm, Types::Integer
    attribute :average_size_mm, Types::Integer
    attribute :minimum_weight_gm, Types::Float
    attribute :maximum_weight_gm, Types::Float
    attribute :average_weight_gm, Types::Float
    attribute :product_code, Types::String
    attribute :system_code, Types::String
    attribute :extended_description, Types::String
    attribute? :active, Types::Bool
  end
end
