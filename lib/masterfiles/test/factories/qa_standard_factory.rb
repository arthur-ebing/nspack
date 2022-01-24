# frozen_string_literal: true

# ========================================================= #
# NB. Scaffolds for test factories should be combined       #
#     - Otherwise you'll have methods for the same table in #
#       several factories.                                  #
#     - Rather create a factory for several related tables  #
# ========================================================= #

module MasterfilesApp
  module QaStandardFactory
    def create_qa_standard(opts = {})
      id = get_available_factory_record(:qa_standards, opts)
      return id unless id.nil?

      # season_id = create_season
      opts[:season_id] ||= create_season
      # qa_standard_type_id = create_qa_standard_type
      opts[:qa_standard_type_id] ||= create_qa_standard_type

      default = {
        qa_standard_name: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        # season_id: season_id,
        # qa_standard_type_id: qa_standard_type_id,
        target_market_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        packed_tm_group_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        internal_standard: false,
        applies_to_all_markets: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:qa_standards].insert(default.merge(opts))
    end

    def create_season(opts = {})
      id = get_available_factory_record(:seasons, opts)
      return id unless id.nil?

      # season_group_id = create_season_group
      opts[:season_group_id] ||= create_season_group
      # commodity_id = create_commodity
      opts[:commodity_id] ||= create_commodity

      default = {
        # season_group_id: season_group_id,
        # commodity_id: commodity_id,
        season_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        season_year: Faker::Number.number(digits: 4),
        start_date: '2010-01-01',
        end_date: '2010-01-01',
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:seasons].insert(default.merge(opts))
    end

    def create_season_group(opts = {})
      id = get_available_factory_record(:season_groups, opts)
      return id unless id.nil?

      default = {
        season_group_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        season_group_year: Faker::Number.number(digits: 4),
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:season_groups].insert(default.merge(opts))
    end

    def create_commodity(opts = {})
      id = get_available_factory_record(:commodities, opts)
      return id unless id.nil?

      # commodity_group_id = create_commodity_group
      opts[:commodity_group_id] ||= create_commodity_group

      default = {
        # commodity_group_id: commodity_group_id,
        code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        hs_code: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        requires_standard_counts: false,
        use_size_ref_for_edi: false,
        colour_applies: false
      }
      DB[:commodities].insert(default.merge(opts))
    end

    def create_commodity_group(opts = {})
      id = get_available_factory_record(:commodity_groups, opts)
      return id unless id.nil?

      default = {
        code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:commodity_groups].insert(default.merge(opts))
    end

    def create_qa_standard_type(opts = {})
      id = get_available_factory_record(:qa_standard_types, opts)
      return id unless id.nil?

      default = {
        qa_standard_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:qa_standard_types].insert(default.merge(opts))
    end
  end
end
