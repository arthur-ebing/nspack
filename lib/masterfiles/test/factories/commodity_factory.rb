# frozen_string_literal: true

module MasterfilesApp
  module CommodityFactory
    def create_commodity(opts = {})
      commodity_group_id = create_commodity_group
      default = {
        commodity_group_id: commodity_group_id,
        code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        hs_code: Faker::Lorem.word,
        active: true,
        requires_standard_counts: false,
        use_size_ref_for_edi: false
      }
      DB[:commodities].insert(default.merge(opts))
    end

    def create_commodity_group(opts = {})
      default = {
        code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true
      }
      DB[:commodity_groups].insert(default.merge(opts))
    end
  end
end
