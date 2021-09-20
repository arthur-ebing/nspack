# frozen_string_literal: true

module MasterfilesApp
  module TargetMarketFactory
    def create_marketing_variety(opts = {})
      id = get_available_factory_record(:marketing_varieties, opts)
      return id unless id.nil?

      default = {
        marketing_variety_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true
      }
      DB[:marketing_varieties].insert(default.merge(opts))
    end

    def create_target_market_group(opts = {})
      id = get_available_factory_record(:target_market_groups, opts)
      return id unless id.nil?

      target_market_group_type_id = create_target_market_group_type(force_create: true)
      default = {
        target_market_group_type_id: target_market_group_type_id,
        target_market_group_name: Faker::Lorem.word,
        description: Faker::Lorem.word,
        active: true,
        local_tm_group: false
      }
      DB[:target_market_groups].insert(default.merge(opts))
    end

    def create_target_market_group_type(opts = {})
      id = get_available_factory_record(:target_market_group_types, opts)
      return id unless id.nil?

      default = {
        target_market_group_type_code: Faker::Lorem.unique.word,
        active: true
      }
      DB[:target_market_group_types].insert(default.merge(opts))
    end

    def create_target_market(opts = {})
      id = get_available_factory_record(:target_markets, opts)
      return id unless id.nil?

      default = {
        target_market_name: Faker::Lorem.unique.word,
        active: true,
        description: Faker::Lorem.word,
        inspection_tm: false
      }
      DB[:target_markets].insert(default.merge(opts))
    end
  end
end
