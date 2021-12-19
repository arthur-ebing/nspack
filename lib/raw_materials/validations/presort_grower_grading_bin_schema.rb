# frozen_string_literal: true

module RawMaterialsApp
  NewPresortGrowerGradingBinSchema = Dry::Schema.Params do
    required(:presort_grower_grading_pool_id).filled(:integer)
    required(:farm_id).filled(:integer)
    required(:maf_rmt_code).maybe(Types::StrippedString)
    required(:maf_article).maybe(Types::StrippedString)
    required(:maf_class).maybe(Types::StrippedString)
    required(:maf_colour).maybe(Types::StrippedString)
    required(:maf_count).maybe(Types::StrippedString)
    required(:maf_article_count).maybe(Types::StrippedString)
    required(:maf_weight).maybe(:decimal)
    required(:maf_tipped_quantity).maybe(:integer)
    required(:maf_total_lot_weight).maybe(:decimal)
    required(:created_by).filled(Types::StrippedString)
    required(:rmt_class_id).maybe(:integer)
    required(:rmt_size_id).maybe(:integer)
    required(:treatment_id).maybe(:integer)
    required(:rmt_bin_weight).maybe(:decimal)
  end

  EditPresortGrowerGradingBinSchema = Dry::Schema.Params do
    required(:maf_colour).maybe(Types::StrippedString)
    required(:maf_class).maybe(Types::StrippedString)
    required(:maf_count).maybe(Types::StrippedString)
    required(:maf_weight).maybe(:decimal)
    required(:updated_by).filled(Types::StrippedString)
    required(:rmt_class_id).maybe(:integer)
    required(:rmt_size_id).maybe(:integer)
    required(:treatment_id).maybe(:integer)
    required(:rmt_bin_weight).maybe(:decimal)
  end

  PresortGrowerGradingBinSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:presort_grower_grading_pool_id).filled(:integer)
    required(:farm_id).filled(:integer)
    required(:rmt_class_id).maybe(:integer)
    required(:rmt_size_id).maybe(:integer)
    required(:treatment_id).maybe(:integer)
    required(:rmt_bin_weight).maybe(:decimal)
    required(:maf_rmt_code).maybe(Types::StrippedString)
    required(:maf_article).maybe(Types::StrippedString)
    required(:maf_class).maybe(Types::StrippedString)
    required(:maf_colour).maybe(Types::StrippedString)
    required(:maf_count).maybe(Types::StrippedString)
    required(:maf_article_count).maybe(Types::StrippedString)
    required(:maf_weight).maybe(:decimal)
    required(:maf_tipped_quantity).maybe(:integer)
    required(:maf_total_lot_weight).maybe(:decimal)
    required(:created_by).maybe(Types::StrippedString)
    optional(:updated_by).maybe(Types::StrippedString)
    optional(:graded).maybe(:bool)
  end
end
