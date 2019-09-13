# frozen_string_literal: true

# ========================================================= #
# NB. Scaffolds for test factories should be combined       #
#     - Otherwise you'll have methods for the same table in #
#       several factories.                                  #
#     - Rather create a factory for several related tables  #
# ========================================================= #

module RawMaterialsApp
  module RmtDeliveryFactory
    def create_rmt_delivery(opts = {})
      orchard_id = create_orchard
      cultivar_id = create_cultivar
      rmt_delivery_destination_id = create_rmt_delivery_destination
      season_id = create_season
      farm_id = create_farm
      puc_id = create_puc

      default = {
        orchard_id: orchard_id,
        cultivar_id: cultivar_id,
        rmt_delivery_destination_id: rmt_delivery_destination_id,
        season_id: season_id,
        farm_id: farm_id,
        puc_id: puc_id,
        truck_registration_number: Faker::Lorem.unique.word,
        qty_damaged_bins: Faker::Number.number(4),
        qty_empty_bins: Faker::Number.number(4),
        active: true,
        delivery_tipped: false,
        date_picked: '2010-01-01',
        date_delivered: '2010-01-01 12:00',
        tipping_complete_date_time: '2010-01-01 12:00',
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:rmt_deliveries].insert(default.merge(opts))
    end

    def create_rmt_delivery_destination(opts = {})
      default = {
        delivery_destination_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:rmt_delivery_destinations].insert(default.merge(opts))
    end
  end
end
