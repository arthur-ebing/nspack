# frozen_string_literal: true

module FinishedGoodsApp
  module LoadFactory # rubocop:disable Metrics/ModuleLength
    def create_load(opts = {}) # rubocop:disable Metrics/AbcSize
      party_role_id = create_party_role[:id]
      destination_city_id = create_destination_city
      depot_id = create_depot
      voyage_id = create_voyage
      pol_voyage_port_id = create_voyage_port(voyage_id: voyage_id)
      pod_voyage_port_id = create_voyage_port(voyage_id: voyage_id)

      default = {
        customer_party_role_id: party_role_id,
        consignee_party_role_id: party_role_id,
        billing_client_party_role_id: party_role_id,
        exporter_party_role_id: party_role_id,
        final_receiver_party_role_id: party_role_id,
        final_destination_id: destination_city_id,
        depot_id: depot_id,
        pol_voyage_port_id: pol_voyage_port_id,
        pod_voyage_port_id: pod_voyage_port_id,
        order_number: Faker::Lorem.unique.word,
        edi_file_name: Faker::Lorem.word,
        customer_order_number: Faker::Lorem.word,
        customer_reference: Faker::Lorem.word,
        exporter_certificate_code: Faker::Lorem.word,
        shipped_at: '2010-01-01',
        shipped: false,
        transfer_load: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:loads].insert(default.merge(opts))
    end

    def create_depot(opts = {})
      destination_city_id = create_destination_city

      default = {
        city_id: destination_city_id,
        depot_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        edi_hub_address: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:depots].insert(default.merge(opts))
    end

    def create_voyage_port(opts = {})
      voyage_id = create_voyage
      port_id = create_port
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
        updated_at: '2010-01-01 12:00'
      }
      DB[:voyage_ports].insert(default.merge(opts))
    end

    def create_voyage(opts = {})
      vessel_id = create_vessel
      voyage_type_id = create_voyage_type

      default = {
        vessel_id: vessel_id,
        voyage_type_id: voyage_type_id,
        voyage_number: Faker::Lorem.unique.word,
        voyage_code: Faker::Lorem.unique.word,
        year: Faker::Number.number(4),
        completed: false,
        completed_at: '2010-01-01 12:00',
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:voyages].insert(default.merge(opts))
    end

    def create_vessel(opts = {})
      vessel_type_id = create_vessel_type

      default = {
        vessel_type_id: vessel_type_id,
        vessel_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:vessels].insert(default.merge(opts))
    end

    def create_vessel_type(opts = {})
      voyage_type_id = create_voyage_type

      default = {
        voyage_type_id: voyage_type_id,
        vessel_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:vessel_types].insert(default.merge(opts))
    end

    def create_voyage_type(opts = {})
      default = {
        voyage_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:voyage_types].insert(default.merge(opts))
    end

    def create_port(opts = {})
      port_type_id = create_port_type
      voyage_type_id = create_voyage_type

      default = {
        port_type_id: port_type_id,
        voyage_type_id: voyage_type_id,
        port_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:ports].insert(default.merge(opts))
    end

    def create_port_type(opts = {})
      default = {
        port_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:port_types].insert(default.merge(opts))
    end
  end
end
