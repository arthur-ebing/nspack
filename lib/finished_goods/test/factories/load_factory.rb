# frozen_string_literal: true

module FinishedGoodsApp
  module LoadFactory # rubocop:disable Metrics/ModuleLength
    def create_load(opts = {}) # rubocop:disable Metrics/AbcSize
      location_id = create_location
      customer_party_role_id = create_party_role[:id]
      consignee_party_role_id = create_party_role[:id]
      billing_client_party_role_id = create_party_role[:id]
      exporter_party_role_id = create_party_role[:id]
      final_receiver_party_role_id = create_party_role[:id]
      destination_city_id = create_destination_city
      pol_voyage_port_id = create_voyage_port
      pod_voyage_port_id = create_voyage_port
      default = {
        depot_location_id: location_id,
        customer_party_role_id: customer_party_role_id,
        consignee_party_role_id: consignee_party_role_id,
        billing_client_party_role_id: billing_client_party_role_id,
        exporter_party_role_id: exporter_party_role_id,
        final_receiver_party_role_id: final_receiver_party_role_id,
        final_destination_id: destination_city_id,
        pol_voyage_port_id: pol_voyage_port_id,
        pod_voyage_port_id: pod_voyage_port_id,
        order_number: Faker::Lorem.unique.word,
        edi_file_name: Faker::Lorem.word,
        customer_order_number: Faker::Lorem.word,
        customer_reference: Faker::Lorem.word,
        exporter_certificate_code: Faker::Lorem.word,
        shipped_date: '2010-01-01 12:00:00',
        shipped: false,
        transfer_load: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:loads].insert(default.merge(opts))
    end

    def create_location(opts = {})
      location_storage_type_id = create_location_storage_type
      location_type_id = create_location_type
      location_assignment_id = create_location_assignment
      location_storage_definition_id = create_location_storage_definition

      default = {
        primary_storage_type_id: location_storage_type_id,
        location_type_id: location_type_id,
        primary_assignment_id: location_assignment_id,
        location_long_code: Faker::Lorem.unique.word,
        location_description: Faker::Lorem.word,
        active: true,
        has_single_container: false,
        virtual_location: false,
        consumption_area: false,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        location_short_code: Faker::Lorem.unique.word,
        can_be_moved: false,
        print_code: Faker::Lorem.word,
        location_storage_definition_id: location_storage_definition_id,
        can_store_stock: false
      }
      DB[:locations].insert(default.merge(opts))
    end

    def create_location_storage_type(opts = {})
      default = {
        storage_type_code: Faker::Lorem.unique.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        location_short_code_prefix: Faker::Lorem.word
      }
      DB[:location_storage_types].insert(default.merge(opts))
    end

    def create_location_type(opts = {})
      default = {
        location_type_code: Faker::Lorem.unique.word,
        short_code: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        can_be_moved: false
      }
      DB[:location_types].insert(default.merge(opts))
    end

    def create_location_assignment(opts = {})
      default = {
        assignment_code: Faker::Lorem.unique.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:location_assignments].insert(default.merge(opts))
    end

    def create_location_storage_definition(opts = {})
      default = {
        storage_definition_code: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        storage_definition_format: Faker::Lorem.word,
        storage_definition_description: Faker::Lorem.word
      }
      DB[:location_storage_definitions].insert(default.merge(opts))
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
