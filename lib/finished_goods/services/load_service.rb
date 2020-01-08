# frozen_string_literal: true

module FinishedGoodsApp
  class LoadService < BaseService
    attr_reader :user_name, :params, :voyage_id, :load_id

    def initialize(load_id, params, user_name)
      @params = params.to_h
      @load_id = load_id
      @user_name = user_name
    end

    def call
      find_or_create_voyage
      create_or_update_load
      create_or_update_load_voyage

      success_response('ok', load_id)
    end

    private

    def find_or_create_voyage
      voyage_attrs = params.slice(:voyage_type_id, :vessel_id, :voyage_number, :year)
      args = voyage_attrs
      args[:active] = true
      args[:completed] = false

      @voyage_id = repo.get_with_args(:voyages, :id, args)
      return unless @voyage_id.nil?

      @voyage_id = repo.create(:voyages, voyage_attrs)
      repo.log_status(:voyages, voyage_id, 'CREATED', user_name: user_name)
    end

    def find_or_create_voyage_port(args)
      voyage_port_id = repo.get_with_args(:voyage_ports, :id, args)
      return voyage_port_id unless voyage_port_id.nil?

      voyage_port_id = repo.create(:voyage_ports, args)
      repo.log_status(:voyage_ports, voyage_port_id, 'CREATED', user_name: user_name)
      voyage_port_id
    end

    def create_or_update_load # rubocop:disable Metrics/AbcSize
      load_attrs = params.slice(:customer_party_role_id,
                                :exporter_party_role_id,
                                :billing_client_party_role_id,
                                :consignee_party_role_id,
                                :final_receiver_party_role_id,
                                :order_number,
                                :customer_order_number,
                                :customer_reference,
                                :shipped_at,
                                :depot_id,
                                :exporter_certificate_code,
                                :final_destination_id,
                                :transfer_load)

      pol_port_type_id = repo.get_with_args(:port_types, :id, port_type_code: AppConst::PORT_TYPE_POL)
      pod_port_type_id = repo.get_with_args(:port_types, :id, port_type_code: AppConst::PORT_TYPE_POD)
      load_attrs[:pol_voyage_port_id] = find_or_create_voyage_port(voyage_id: voyage_id,
                                                                   port_id: params[:pol_port_id],
                                                                   port_type_id: pol_port_type_id)
      load_attrs[:pod_voyage_port_id] = find_or_create_voyage_port(voyage_id: voyage_id,
                                                                   port_id: params[:pod_port_id],
                                                                   port_type_id: pod_port_type_id)
      if @load_id.nil?
        @load_id = repo.create(:loads, load_attrs)
        repo.log_status(:loads, load_id, 'CREATED', user_name: user_name)
      else
        repo.update(:loads, load_id, load_attrs)
        repo.log_status(:loads, load_id, 'UPDATED', user_name: user_name)
      end
    end

    def create_or_update_load_voyage # rubocop:disable Metrics/AbcSize
      load_voyage_attrs = params.slice(:shipping_line_party_role_id,
                                       :shipper_party_role_id,
                                       :booking_reference,
                                       :memo_pad)
      load_voyage_attrs[:load_id] = load_id
      load_voyage_attrs[:voyage_id] = voyage_id

      load_voyage_id = repo.get_with_args(:load_voyages, :id, load_id: load_id)
      if load_voyage_id.nil?
        load_voyage_id = repo.create(:load_voyages, load_voyage_attrs)
        repo.log_status(:load_voyages, load_voyage_id, 'CREATED', user_name: user_name)
      else
        repo.update(:load_voyages, load_voyage_id, load_voyage_attrs)
        repo.log_status(:load_voyages, load_voyage_id, 'UPDATED', user_name: user_name)
      end
    end

    def repo
      @repo ||= LoadRepo.new
    end
  end
end
