# frozen_string_literal: true

module FinishedGoodsApp
  module LoadFactory
    def create_load(opts = {}) # rubocop:disable Metrics/AbcSize
      repo = BaseRepo.new
      pol_port_type_id = repo.get_with_args(:port_types, :id, port_type_code: AppConst::PORT_TYPE_POL) || create_port_type(port_type_code: AppConst::PORT_TYPE_POL)
      pod_port_type_id = repo.get_with_args(:port_types, :id, port_type_code: AppConst::PORT_TYPE_POD) || create_port_type(port_type_code: AppConst::PORT_TYPE_POD)

      party_role_id = create_party_role[:id]
      destination_city_id = create_destination_city
      depot_id = create_depot
      voyage_id = create_voyage
      pol_voyage_port_id = create_voyage_port(voyage_id: voyage_id, port_type_id: pol_port_type_id)
      pod_voyage_port_id = create_voyage_port(voyage_id: voyage_id, port_type_id: pod_port_type_id)

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
  end
end
