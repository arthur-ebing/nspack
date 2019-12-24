# frozen_string_literal: true

module FinishedGoodsApp
  module VoyagePortFactory
    def create_voyage_port(opts = {})
      voyage_id = create_voyage
      port_id = create_port
      port_type_id = create_port_type
      vessel_id = create_vessel

      default = {
        voyage_id: voyage_id,
        port_id: port_id,
        trans_shipment_vessel_id: vessel_id,
        ata: '2010-01-01',
        atd: '2010-01-01',
        eta: '2010-01-01',
        etd: '2010-01-01',
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        port_type_id: port_type_id
      }
      DB[:voyage_ports].insert(default.merge(opts))
    end
  end
end
