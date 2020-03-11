# frozen_string_literal: true

module MasterfilesApp
  module CultivarFactory
    def create_cultivar_group(opts = {})
      commodity_id = create_commodity
      default = {
        commodity_id: commodity_id,
        cultivar_group_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true
      }
      DB[:cultivar_groups].insert(default.merge(opts))
    end

    def create_cultivar(opts = {})
      commodity_id = create_commodity
      cultivar_group_id = create_cultivar_group

      default = {
        commodity_id: commodity_id,
        cultivar_group_id: cultivar_group_id,
        cultivar_name: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        cultivar_code: Faker::Lorem.word,
        active: true
      }
      DB[:cultivars].insert(default.merge(opts))
    end
  end
end
