# frozen_string_literal: true

module FinishedGoodsApp
  module LoadVoyageFactory
    def create_load_voyage(opts = {})
      load_id = create_load
      voyage_id = create_voyage
      shipping_line_party_role_id = create_party_role('O', AppConst::ROLE_SHIPPING_LINE)
      shipper_party_role_id = create_party_role('O', AppConst::ROLE_SHIPPER)

      default = {
        load_id: load_id,
        voyage_id: voyage_id,
        shipping_line_party_role_id: shipping_line_party_role_id,
        shipper_party_role_id: shipper_party_role_id,
        booking_reference: Faker::Lorem.unique.word,
        memo_pad: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:load_voyages].insert(default.merge(opts))
    end
  end
end
