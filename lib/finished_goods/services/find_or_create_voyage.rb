# frozen_string_literal: true

module FinishedGoodsApp
  module FindOrCreateVoyage
    def find_voyage
      params[:active] = true
      params[:completed] = false
      @params = params.merge(voyage_repo.find_voyage_with_ports(params))
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

    def voyage_repo
      @voyage_repo ||= VoyageRepo.new
    end

    def validate_voyage_params(params)
      VoyageSchema.call(params)
    end
  end
end
