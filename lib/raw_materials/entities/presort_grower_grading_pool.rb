# frozen_string_literal: true

module RawMaterialsApp
  class PresortGrowerGradingPool < Dry::Struct
    attribute :id, Types::Integer
    attribute :maf_lot_number, Types::String
    attribute :description, Types::String
    attribute :track_slms_indicator_code, Types::String
    attribute :season_id, Types::Integer
    attribute :commodity_id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :rmt_bin_count, Types::Integer
    attribute :rmt_bin_weight, Types::Decimal
    attribute :pro_rata_factor, Types::Decimal
    attribute :completed, Types::Bool
    attribute :created_by, Types::String
    attribute :updated_by, Types::String
    attribute? :active, Types::Bool
    attribute :created_at, Types::DateTime
    attribute :updated_at, Types::DateTime
  end

  class PresortGrowerGradingPoolFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :maf_lot_number, Types::String
    attribute :description, Types::String
    attribute :track_slms_indicator_code, Types::String
    attribute :season_id, Types::Integer
    attribute :commodity_id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :rmt_bin_count, Types::Integer
    attribute :rmt_bin_weight, Types::Decimal
    attribute :pro_rata_factor, Types::Decimal
    attribute :completed, Types::Bool
    attribute :created_by, Types::String
    attribute :updated_by, Types::String
    attribute? :active, Types::Bool
    attribute :created_at, Types::DateTime
    attribute :updated_at, Types::DateTime
    attribute :commodity_code, Types::String
    attribute :season_code, Types::String
    attribute :farm_code, Types::String
    attribute :total_graded_weight, Types::Decimal
  end
end
