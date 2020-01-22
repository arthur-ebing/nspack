# frozen_string_literal: true

module FinishedGoodsApp
  class UpdateLoad < BaseService
    include FindOrCreateVoyage
    attr_reader :params, :load_id, :load_voyage_id

    def initialize(params, user)
      @params = params.to_h
      @load_id = @params[:load_id]
      @user = user
    end

    def call
      res = find_voyage
      create_voyage unless res.success

      update_load
      update_pallets_shipped_at unless @params[:shipped_at].nil?
      update_load_voyage

      instance = load_entity(load_id)
      success_response("Updated load: #{load_id}", instance)
    end

    private

    def update_load
      repo.update(:loads, load_id, validate_load_params(params))
      repo.log_status(:loads, load_id, 'UPDATED', user_name: @user.user_name)
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
  end
end
