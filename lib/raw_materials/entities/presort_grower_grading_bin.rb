# frozen_string_literal: true

module RawMaterialsApp
  class PresortGrowerGradingBin < Dry::Struct
    attribute :id, Types::Integer
    attribute :presort_grower_grading_pool_id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :rmt_class_id, Types::Integer
    attribute :rmt_size_id, Types::Integer
    attribute :maf_rmt_code, Types::String
    attribute :maf_article, Types::String
    attribute :maf_class, Types::String
    attribute :maf_colour, Types::String
    attribute :maf_count, Types::String
    attribute :maf_article_count, Types::String
    attribute :maf_weight, Types::Decimal
    attribute :maf_tipped_quantity, Types::Integer
    attribute :maf_total_lot_weight, Types::Decimal
    attribute :created_by, Types::String
    attribute :updated_by, Types::String
    attribute :colour_percentage_id, Types::Integer
    attribute :rmt_bin_weight, Types::Decimal
    attribute? :graded, Types::Bool
    attribute? :active, Types::Bool
    attribute :created_at, Types::DateTime
    attribute :updated_at, Types::DateTime
  end

  class PresortGrowerGradingBinFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :presort_grower_grading_pool_id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :rmt_class_id, Types::Integer
    attribute :rmt_size_id, Types::Integer
    attribute :maf_rmt_code, Types::String
    attribute :maf_article, Types::String
    attribute :maf_class, Types::String
    attribute :maf_colour, Types::String
    attribute :maf_count, Types::String
    attribute :maf_article_count, Types::String
    attribute :maf_weight, Types::Decimal
    attribute :maf_tipped_quantity, Types::Integer
    attribute :maf_total_lot_weight, Types::Decimal
    attribute :created_by, Types::String
    attribute :updated_by, Types::String
    attribute :colour_percentage_id, Types::Integer
    attribute :rmt_bin_weight, Types::Decimal
    attribute :adjusted_weight, Types::Decimal
    attribute? :graded, Types::Bool
    attribute? :active, Types::Bool
    attribute :created_at, Types::DateTime
    attribute :updated_at, Types::DateTime
    attribute :maf_lot_number, Types::String
    attribute :farm_code, Types::String
    attribute :rmt_class_code, Types::String
    attribute :rmt_size_code, Types::String
    attribute :colour, Types::String
  end
end
