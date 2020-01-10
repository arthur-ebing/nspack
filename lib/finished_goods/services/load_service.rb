# frozen_string_literal: true

module FinishedGoodsApp
  class LoadService < BaseService
    attr_reader :params, :load_id, :load_voyage_id

    def initialize(params:, user:, route_url:, request_ip:)
      @params = params.to_h
      @load_id = @params[:load_id]
      @load_voyage_id = repo.get_with_args(:load_voyages, :id, load_id: @load_id)
      @pol_port_type_id = repo.get_with_args(:port_types, :id, port_type_code: AppConst::PORT_TYPE_POL)
      @pod_port_type_id = repo.get_with_args(:port_types, :id, port_type_code: AppConst::PORT_TYPE_POD)

      @load_interactor = LoadInteractor.new(user, {}, { route_url: route_url, request_ip: request_ip }, {})
      @voyage_interactor = VoyageInteractor.new(user, {}, { route_url: route_url, request_ip: request_ip }, {})
      @voyage_port_interactor = VoyagePortInteractor.new(user, {}, { route_url: route_url, request_ip: request_ip }, {})
      @load_voyage_interactor = LoadVoyageInteractor.new(user, {}, { route_url: route_url, request_ip: request_ip }, {})
    end

    def call
      res = LoadServiceSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      find_or_create_voyage

      update_or_create_load
      update_shipped_at unless @params[:shipped_at].nil?

      update_or_create_load_voyage

      success_response(@message, params[:load_id])
    end

    private

    def find_or_create_voyage # rubocop:disable Metrics/AbcSize
      params[:active] = true
      params[:completed] = false
      @params = params.merge(VoyageRepo.new.find_voyage_with_ports(params))
      return ok_response unless params[:voyage_id].nil?

      params[:voyage_id] = @voyage_interactor.create_voyage(params).instance.id

      attrs = { voyage_id: params[:voyage_id], port_id: params[:pol_port_id], port_type_id: @pol_port_type_id }
      params[:pol_voyage_port_id] = @voyage_port_interactor.create_voyage_port(attrs).instance.id

      attrs = { voyage_id: params[:voyage_id], port_id: params[:pod_port_id], port_type_id: @pod_port_type_id }
      params[:pod_voyage_port_id] = @voyage_port_interactor.create_voyage_port(attrs).instance.id

      ok_response
    end

    def update_or_create_load
      res = load_id.nil? ? @load_interactor.create_load(params) : @load_interactor.update_load(load_id, params)
      params[:load_id] = res.instance.id
      @message = res.message
    end

    def update_or_create_load_voyage
      load_voyage_id.nil? ? @load_voyage_interactor.create_load_voyage(params) : @load_voyage_interactor.update_load_voyage(load_voyage_id, params)
    end

    def update_shipped_at
      repo.update_shipped_at(load_id: params[:load_id], shipped_at: params[:shipped_at])
    end

    def repo
      @repo ||= LoadRepo.new
    end
  end
end
