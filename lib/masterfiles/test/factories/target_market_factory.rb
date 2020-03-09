# frozen_string_literal: true

module MasterfilesApp
  module TargetMarketFactory
    def create_marketing_variety(opts = {})
      default = {
        marketing_variety_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true
      }
      DB[:marketing_varieties].insert(default.merge(opts))
    end

    def create_target_market_group(opts = {})
      target_market_group_type_id = create_target_market_group_type

      default = {
        target_market_group_type_id: target_market_group_type_id,
        target_market_group_name: Faker::Lorem.word,
        description: Faker::Lorem.word,
        active: true
      }
      DB[:target_market_groups].insert(default.merge(opts))
    end

    def create_target_market_group_type(opts = {})
      default = {
        target_market_group_type_code: Faker::Lorem.unique.word,
        active: true
      }
      DB[:target_market_group_types].insert(default.merge(opts))
    end
  end
end
