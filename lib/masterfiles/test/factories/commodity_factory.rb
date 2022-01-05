# frozen_string_literal: true

module MasterfilesApp
  module CommodityFactory
    def create_commodity(opts = {})
      id = get_available_factory_record(:commodities, opts)
      return id unless id.nil?

      commodity_group_id = create_commodity_group
      default = {
        commodity_group_id: commodity_group_id,
        code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        hs_code: Faker::Lorem.word,
        active: true,
        requires_standard_counts: false,
        use_size_ref_for_edi: false,
        colour_applies: false,
        derive_rmt_nett_weight: false
      }
      DB[:commodities].insert(default.merge(opts))
    end

    def create_commodity_group(opts = {})
      id = get_available_factory_record(:commodity_groups, opts)
      return id unless id.nil?

      default = {
        code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true
      }
      DB[:commodity_groups].insert(default.merge(opts))
    end

    def create_colour_percentage(opts = {})
      id = get_available_factory_record(:colour_percentages, opts)
      return id unless id.nil?

      opts[:commodity_id] ||= create_commodity

      default = {

        colour_percentage: Faker::Lorem.word,
        description: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:colour_percentages].insert(default.merge(opts))
    end
  end
end
