# frozen_string_literal: true

module FinishedGoodsApp
  class CreateLoad < BaseService
    include FindOrCreateVoyage
    attr_reader :comment, :user
    attr_accessor :params

    def initialize(params, user, comment: nil)
      @params = params.to_h
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

      instance = load_entity(params[:load_id])
      success_response("Created load: #{params[:load_id]}", instance)
    end

    private

    def create_load
      res = LoadSchema.call(params)
      return validation_failed_response(res) if res.failure?

      attrs = res.to_h
      attrs[:requires_temp_tail] = AppConst::TEMP_TAIL_REQUIRED_TO_SHIP unless attrs[:requires_temp_tail]

      @params[:load_id] = create_with_status(:loads, attrs)
      repo.link_order_to_load(params)

      ok_response
    end

    def create_load_voyage
      res = LoadVoyageSchema.call(params)
      return validation_failed_response(res) if res.failure?

      create_with_status(:load_voyages, res)
      ok_response
    end

    def create_with_status(table_name, args)
      id = repo.create(table_name, args)
      repo.log_status(table_name, id, 'CREATED', user_name: user.user_name, comment: comment)
      id
    end

    def repo
      @repo ||= LoadRepo.new
    end

    def load_entity(id)
      repo.find_load(id)
    end
  end
end
