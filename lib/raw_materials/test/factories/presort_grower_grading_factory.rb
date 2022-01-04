# frozen_string_literal: true

module RawMaterialsApp
  module PresortGrowerGradingFactory
    def create_presort_grower_grading_pool(opts = {})
      id = get_available_factory_record(:presort_grower_grading_pools, opts)
      return id unless id.nil?

      opts[:season_id] ||= create_season
      opts[:farm_id] ||= create_farm
      opts[:commodity_id] ||= create_commodity

      default = {
        maf_lot_number: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        track_slms_indicator_code: Faker::Lorem.word,
        rmt_bin_count: Faker::Number.number(digits: 4),
        rmt_bin_weight: Faker::Number.decimal,
        pro_rata_factor: Faker::Number.decimal,
        completed: false,
        active: true,
        created_by: Faker::Lorem.word,
        updated_by: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:presort_grower_grading_pools].insert(default.merge(opts))
    end

    def create_presort_grower_grading_bin(opts = {})
      id = get_available_factory_record(:presort_grower_grading_bins, opts)
      return id unless id.nil?

      opts[:presort_grower_grading_pool_id] ||= create_presort_grower_grading_pool
      opts[:farm_id] ||= create_farm
      opts[:rmt_class_id] ||= create_rmt_class
      opts[:rmt_size_id] ||= create_rmt_size
      opts[:colour_percentage_id] ||= create_colour_percentage

      default = {
        maf_rmt_code: Faker::Lorem.unique.word,
        maf_article: Faker::Lorem.word,
        maf_class: Faker::Lorem.word,
        maf_colour: Faker::Lorem.word,
        maf_count: Faker::Lorem.word,
        maf_article_count: Faker::Lorem.word,
        maf_weight: Faker::Number.decimal,
        maf_tipped_quantity: Faker::Number.number(digits: 4),
        maf_total_lot_weight: Faker::Number.decimal,
        active: true,
        created_by: Faker::Lorem.word,
        updated_by: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        graded: false,
        rmt_bin_weight: Faker::Number.decimal
      }
      DB[:presort_grower_grading_bins].insert(default.merge(opts))
    end
  end
end
