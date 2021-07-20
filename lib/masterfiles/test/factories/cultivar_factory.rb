# frozen_string_literal: true

module MasterfilesApp
  module CultivarFactory
    def create_cultivar_group(opts = {})
      id = get_available_factory_record(:cultivar_groups, opts)
      return id unless id.nil?

      opts[:commodity_id] ||= create_commodity
      default = {
        cultivar_group_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true
      }
      DB[:cultivar_groups].insert(default.merge(opts))
    end

    def create_cultivar(opts = {})
      id = get_available_factory_record(:cultivars, opts)
      return id unless id.nil?

      opts[:cultivar_group_id] ||= create_cultivar_group
      default = {
        cultivar_name: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        cultivar_code: Faker::Lorem.word,
        active: true
      }
      DB[:cultivars].insert(default.merge(opts))
    end
  end
end
