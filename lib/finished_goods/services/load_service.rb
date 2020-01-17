# frozen_string_literal: true

module FinishedGoodsApp
  class LoadService < BaseService
    attr_reader :params, :load_id, :load_voyage_id

    def initialize(mode:, params:, user:)
      @mode = mode
      @params = params.to_h
      @load_id = @params[:load_id]
      @user = user
    end

    def call
      return create_call if @mode == :create

      update_call if @mode == :update
    end

    private

    def create_call
      res = find_voyage
      create_voyage unless res.success

      create_load
      create_load_voyage

      instance = load_entity(load_id)
      success_response("Created load: #{load_id}", instance)
    end

    def update_call
      res = find_voyage
      create_voyage unless res.success

      update_load
      update_pallets_shipped_at unless @params[:shipped_at].nil?
      update_load_voyage

      instance = load_entity(load_id)
      success_response("Updated load: #{load_id}", instance)
    end

    def find_voyage
      params[:active] = true
      params[:completed] = false
      @params = params.merge(VoyageRepo.new.find_voyage_with_ports(params))
      return ok_response unless params[:voyage_id].nil?

      failed_response('Voyage not found.')
    end

    def create_voyage  # rubocop:disable Metrics/AbcSize
      params[:voyage_id] = repo.create(:voyages, validate_voyage_params(params))
      repo.log_status(:voyages, params[:voyage_id], 'CREATED', user_name: @user.user_name)

      pol_port_type_id = repo.get_with_args(:port_types, :id, port_type_code: AppConst::PORT_TYPE_POL)
      attrs = { voyage_id: params[:voyage_id], port_id: params[:pol_port_id], port_type_id: pol_port_type_id }
      params[:pol_voyage_port_id] = create_voyage_port(attrs)

      pod_port_type_id = repo.get_with_args(:port_types, :id, port_type_code: AppConst::PORT_TYPE_POD)
      attrs = { voyage_id: params[:voyage_id], port_id: params[:pod_port_id], port_type_id: pod_port_type_id }
      params[:pod_voyage_port_id] = create_voyage_port(attrs)
    end

    def create_voyage_port(attrs)
      voyage_port_id = repo.create(:voyage_ports, attrs)
      repo.log_status(:voyage_ports, voyage_port_id, 'CREATED', user_name: @user.user_name)
      voyage_port_id
    end

    def create_load
      @load_id = repo.create(:loads, validate_load_params(params))
      params[:load_id] = load_id
      repo.log_status(:loads, load_id, 'CREATED', user_name: @user.user_name)
    end

    def update_load
      repo.update(:loads, load_id, validate_load_params(params))
      repo.log_status(:loads, load_id, 'UPDATED', user_name: @user.user_name)
    end

    def create_load_voyage
      load_voyage_id = repo.create(:load_voyages, validate_load_voyage_params(params))
      repo.log_status(:load_voyages, load_voyage_id, 'CREATED', user_name: @user.user_name)
    end

    def update_load_voyage
      load_voyage_id = repo.get_with_args(:load_voyages, :id, load_id: load_id)
      repo.update(:load_voyages, load_voyage_id, validate_load_voyage_params(params))
      repo.log_status(:load_voyages, load_voyage_id, 'UPDATED', user_name: @user.user_name)
    end

    def update_pallets_shipped_at
      repo.update_pallets_shipped_at(load_id: load_id, shipped_at: params[:shipped_at])
    end

    def repo
      @repo ||= LoadRepo.new
    end

    def load_entity(id)
      repo.find_load_flat(id)
    end

    def validate_load_params(params)
      LoadSchema.call(params)
    end

    def validate_load_voyage_params(params)
      LoadVoyageSchema.call(params)
    end

    def validate_voyage_params(params)
      VoyageSchema.call(params)
    end

    def validate_voyage_port_params(params)
      VoyagePortSchema.call(params)
    end
  end
end
