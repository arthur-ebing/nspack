# frozen_string_literal: true

module MasterfilesApp
  module MarketingFactory
    def create_mark(opts = {})
      id = get_available_factory_record(:marks, opts)
      return id unless id.nil?

      default = {
        mark_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true
      }
      DB[:marks].insert(default.merge(opts))
    end

    def create_customer_variety(opts = {})
      id = get_available_factory_record(:customer_varieties, opts)
      return id unless id.nil?

      marketing_variety_id = create_marketing_variety(force_create: true)
      target_market_group_id = create_target_market_group(force_create: true)

      default = {
        variety_as_customer_variety_id: marketing_variety_id,
        packed_tm_group_id: target_market_group_id,
        active: true
      }
      DB[:customer_varieties].insert(default.merge(opts))
    end

    def create_customer_variety_variety(opts = {})
      id = get_available_factory_record(:customer_variety_varieties, opts)
      return id unless id.nil?

      customer_variety_id = create_customer_variety(force_create: true)
      marketing_variety_id = create_marketing_variety(force_create: true)

      default = {
        customer_variety_id: customer_variety_id,
        marketing_variety_id: marketing_variety_id,
        active: true
      }
      DB[:customer_variety_varieties].insert(default.merge(opts))
    end
  end
end
