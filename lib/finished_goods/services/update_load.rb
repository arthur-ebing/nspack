# frozen_string_literal: true

module FinishedGoodsApp
  class UpdateLoadService < BaseService
    def initialize(load_id, params, user_name)
      @load_id = load_id
      @params = params.output
      @user_name = user_name
    end

    def call  # rubocop:disable Metrics/AbcSize
      # FIND OR CREATE VOYAGE
      voyage_attrs = @params.slice(:voyage_type_id,
                                   :vessel_id,
                                   :voyage_number,
                                   :year)
      voyage_attrs[:user_name] = @user_name
      voyage_id = VoyageRepo.new.find_or_create_voyage(voyage_attrs)

      # UPDATE LOAD
      load_attrs = @params.slice(:customer_party_role_id,
                                 :exporter_party_role_id,
                                 :billing_client_party_role_id,
                                 :consignee_party_role_id,
                                 :final_receiver_party_role_id,
                                 :order_number,
                                 :customer_order_number,
                                 :customer_reference,
                                 :depot_id,
                                 :exporter_certificate_code,
                                 :final_destination_id,
                                 :transfer_load)
      load_attrs[:pol_voyage_port_id] = VoyagePortRepo.new.find_or_create_voyage_port(voyage_id: voyage_id, port_id: @params[:pol_port_id])
      load_attrs[:pod_voyage_port_id] = VoyagePortRepo.new.find_or_create_voyage_port(voyage_id: voyage_id, port_id: @params[:pod_port_id])

      LoadRepo.new.update_load(@load_id, load_attrs)

      # UPDATE LOAD_VOYAGE
      load_voyage_attrs = @params.slice(:shipping_line_party_role_id,
                                        :shipper_party_role_id,
                                        :booking_reference,
                                        :memo_pad)

      load_voyage_attrs[:voyage_id] = voyage_id
      load_voyage_id = LoadVoyageRepo.new.find_load_voyage_id(@load_id)
      LoadVoyageRepo.new.update_load_voyage(load_voyage_id, load_voyage_attrs)

      success_response('ok', @load_id)
    end
  end
end
