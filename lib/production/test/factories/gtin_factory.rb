# frozen_string_literal: true

module ProductionApp
  module GtinFactory
    def create_gtin(opts = {}) # rubocop:disable Metrics/AbcSize
      default = {
        transaction_number: Faker::Lorem.unique.word,
        gtin_code: Faker::Lorem.word,
        date_to: '2010-01-01 12:00',
        date_from: '2030-01-01 12:00',
        org_code: Faker::Lorem.word,
        commodity_code: Faker::Lorem.word,
        marketing_variety_code: Faker::Lorem.word,
        standard_pack_code: Faker::Lorem.word,
        grade_code: Faker::Lorem.word,
        mark_code: Faker::Lorem.word,
        size_count_code: Faker::Lorem.word,
        inventory_code: Faker::Lorem.word,
        target_market_code: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        commodity_id: Faker::Number.number(digits: 4),
        marketing_variety_id: Faker::Number.number(digits: 4),
        marketing_org_party_role_id: Faker::Number.number(digits: 4),
        standard_pack_code_id: Faker::Number.number(digits: 4),
        mark_id: Faker::Number.number(digits: 4),
        grade_id: Faker::Number.number(digits: 4),
        inventory_code_id: Faker::Number.number(digits: 4),
        packed_tm_group_id: Faker::Number.number(digits: 4),
        std_fruit_size_count_id: Faker::Number.number(digits: 4)
      }
      DB[:gtins].insert(default.merge(opts.slice(default.keys)))
    end
  end
end
