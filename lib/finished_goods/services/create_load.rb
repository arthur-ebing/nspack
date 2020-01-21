# frozen_string_literal: true

module FinishedGoodsApp
  class CreateLoad < BaseService
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

      create_load
      create_load_voyage

      instance = load_entity(load_id)
      success_response("Created load: #{load_id}", instance)
    end

    private

    def create_load
      @load_id = repo.create(:loads, validate_load_params(params))
      @params[:load_id] = load_id
      repo.log_status(:loads, load_id, 'CREATED', user_name: @user.user_name)
    end

    def create_load_voyage
      load_voyage_id = repo.create(:load_voyages, validate_load_voyage_params(params))
      repo.log_status(:load_voyages, load_voyage_id, 'CREATED', user_name: @user.user_name)
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
