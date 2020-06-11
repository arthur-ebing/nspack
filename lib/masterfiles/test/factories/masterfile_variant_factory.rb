# frozen_string_literal: true

module MasterfilesApp
  module MasterfileVariantFactory
    def create_masterfile_variant(opts = {})
      default = {
        masterfile_table: 'target_market_groups',
        variant_code: Faker::Lorem.word,
        masterfile_id: Faker::Number.number(4),
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:masterfile_variants].insert(default.merge(opts))
    end
  end
end
