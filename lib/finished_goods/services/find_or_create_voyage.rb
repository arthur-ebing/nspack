# frozen_string_literal: true

module FinishedGoodsApp
  module FindOrCreateVoyage
    def find_voyage
      params[:active] = true
      params[:completed] = false

      attrs = voyage_repo.find_voyage_with_ports(params)
      params.merge!(attrs)
      return failed_response('Voyage not found') if params[:voyage_id].nil?

      ok_response
    end

    def create_voyage  # rubocop:disable Metrics/AbcSize
      res = validate_voyage_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      params[:voyage_id] = repo.create(:voyages, res)
      repo.log_status(:voyages, params[:voyage_id], 'CREATED', user_name: @user.user_name)

      pol_port_type_id = repo.get_id(:port_types, port_type_code: AppConst::PORT_TYPE_POL)
      attrs = { voyage_id: params[:voyage_id], port_id: params[:pol_port_id], port_type_id: pol_port_type_id }
      res = create_voyage_port(attrs)
      return res unless res.success

      params[:pol_voyage_port_id] = res.instance

      pod_port_type_id = repo.get_id(:port_types, port_type_code: AppConst::PORT_TYPE_POD)
      attrs = { voyage_id: params[:voyage_id], port_id: params[:pod_port_id], port_type_id: pod_port_type_id }
      res = create_voyage_port(attrs)
      return res unless res.success

      params[:pod_voyage_port_id] = res.instance

      ok_response
    end

    def create_voyage_port(attrs)
      res = validate_voyage_port_params(attrs)
      return validation_failed_response(res) unless res.messages.empty?

      voyage_port_id = repo.create(:voyage_ports, res)
      repo.log_status(:voyage_ports, voyage_port_id, 'CREATED', user_name: @user.user_name)
      success_response('ok', voyage_port_id)
    end

    def voyage_repo
      @voyage_repo ||= VoyageRepo.new
    end

    def validate_voyage_params(params)
      VoyageSchema.call(params)
    end

    def validate_voyage_port_params(params)
      VoyagePortSchema.call(params)
    end
  end
end
