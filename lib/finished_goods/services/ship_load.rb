# frozen_string_literal: true

module FinishedGoodsApp
  class ShipLoadService < BaseService
    attr_reader :id, :params, :user_name

    def initialize(id, params, user_name)
      @id = id
      @params = params
      @user_name = user_name
    end

    def call
      ship_load

      success_response('ok', id)
    end

    private

    def ship_load
      repo.ship_load(id, user_name)
    end

    def repo
      @repo ||= LoadRepo.new
    end
  end
end
