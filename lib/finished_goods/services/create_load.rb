# frozen_string_literal: true

module FinishedGoodsApp
  class CreateLoad < BaseService
    include FindOrCreateVoyage
    attr_reader :load_id, :load_voyage_id, :comment
    attr_accessor :params

    def initialize(params, user, comment: nil)
      @params = params.to_h
      @load_id = @params[:load_id]
      @user = user
      @comment = comment
    end

    def call
      res = find_voyage
      res = create_voyage unless res.success
      return res unless res.success

      res = create_load
      return res unless res.success

      res = create_load_voyage
      return res unless res.success

      instance = load_entity(load_id)
      success_response("Created load: #{load_id}", instance)
    end

    private

    def create_load # rubocop:disable Metrics/AbcSize
      res = LoadSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      attrs = res.to_h
      attrs[:requires_temp_tail] = AppConst::TEMP_TAIL_REQUIRED_TO_SHIP unless attrs[:requires_temp_tail]

      @load_id = repo.create(:loads, attrs)
      @params[:load_id] = load_id
      repo.log_status(:loads, load_id, 'CREATED', user_name: @user.user_name, comment: comment)

      ok_response
    end

    def create_load_voyage
      res = LoadVoyageSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      load_voyage_id = repo.create(:load_voyages, res)
      repo.log_status(:load_voyages, load_voyage_id, 'CREATED', user_name: @user.user_name, comment: comment)

      ok_response
    end

    def repo
      @repo ||= LoadRepo.new
    end

    def load_entity(id)
      repo.find_load_flat(id)
    end
  end
end
