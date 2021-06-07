# frozen_string_literal: true

module FinishedGoodsApp
  class UpdateLoad < BaseService
    include FindOrCreateVoyage
    attr_reader :load_id, :load_voyage_id
    attr_accessor :params

    def initialize(id, params, user)
      @params = params.to_h
      @load_id = id
      @user = user
    end

    def call # rubocop:disable Metrics/AbcSize
      res = find_voyage
      res = create_voyage unless res.success
      return res unless res.success

      res = update_load
      return res unless res.success

      update_pallets_shipped_at unless @params[:shipped_at].nil?

      res = update_load_voyage
      return res unless res.success

      instance = load_entity(load_id)
      success_response("Updated load: #{load_id}", instance)
    end

    private

    def update_load
      res = LoadSchema.call(params)
      return validation_failed_response(res) if res.failure?

      attrs = res.to_h
      attrs[:requires_temp_tail] = AppConst::TEMP_TAIL_REQUIRED_TO_SHIP unless attrs[:requires_temp_tail]

      repo.update(:loads, load_id, attrs)
      repo.log_status(:loads, load_id, 'UPDATED', user_name: @user.user_name)

      ok_response
    end

    def update_load_voyage
      res = LoadVoyageSchema.call(params)
      return validation_failed_response(res) if res.failure?

      load_voyage_id = repo.get_id(:load_voyages, load_id: load_id)
      repo.update(:load_voyages, load_voyage_id, res)
      repo.log_status(:load_voyages, load_voyage_id, 'UPDATED', user_name: @user.user_name)

      ok_response
    end

    def update_pallets_shipped_at
      repo.update_pallets_shipped_at(load_id, params[:shipped_at])
    end

    def repo
      @repo ||= LoadRepo.new
    end

    def load_entity(id)
      repo.find_load(id)
    end
  end
end
