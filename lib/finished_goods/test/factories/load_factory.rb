# frozen_string_literal: true

module FinishedGoodsApp
  module LoadFactory
    def create_load(opts = {}) # rubocop:disable Metrics/AbcSize
      customer_party_role_id = create_party_role[:id]
      consignee_party_role_id = create_party_role[:id]
      billing_client_party_role_id = create_party_role[:id]
      exporter_party_role_id = create_party_role[:id]
      final_receiver_party_role_id = create_party_role[:id]
      destination_city_id = create_destination_city
      depot_id = create_depot
      pol_voyage_port_id = create_voyage_port
      pod_voyage_port_id = create_voyage_port
      default = {
        customer_party_role_id: customer_party_role_id,
        consignee_party_role_id: consignee_party_role_id,
        billing_client_party_role_id: billing_client_party_role_id,
        exporter_party_role_id: exporter_party_role_id,
        final_receiver_party_role_id: final_receiver_party_role_id,
        final_destination_id: destination_city_id,
        depot_id: depot_id,
        pol_voyage_port_id: pol_voyage_port_id,
        pod_voyage_port_id: pod_voyage_port_id,
        order_number: Faker::Lorem.unique.word,
        edi_file_name: Faker::Lorem.word,
        customer_order_number: Faker::Lorem.word,
        customer_reference: Faker::Lorem.word,
        exporter_certificate_code: Faker::Lorem.word,
        shipped_date: '2010-01-01 12:00',
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
        edi_code: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:depots].insert(default.merge(opts))
    end

    def create_destination_city(opts = {})
      destination_country_id = create_destination_country

      default = {
        destination_country_id: destination_country_id,
        city_name: Faker::Lorem.unique.word,
        active: true,
        updated_at: '2010-01-01 12:00',
        created_at: '2010-01-01 12:00'
      }
      DB[:destination_cities].insert(default.merge(opts))
    end

    def create_destination_country(opts = {})
      destination_region_id = create_destination_region

      default = {
        destination_region_id: destination_region_id,
        country_name: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:destination_countries].insert(default.merge(opts))
    end

    def create_destination_region(opts = {})
      default = {
        destination_region_name: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:destination_regions].insert(default.merge(opts))
    end
  end
end
