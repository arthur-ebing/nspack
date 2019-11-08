# frozen_string_literal: true

module FinishedGoodsApp
  class ShipLoad < BaseService
    attr_reader :load_id, :pallet_numbers, :user_name

    def initialize(load_id, user_name)
      @load_id = load_id
      @pallet_numbers = FinishedGoodsApp::LoadRepo.new.find_pallet_numbers_from(load_id: load_id).flatten
      @user_name = user_name
    end

    def call
      ship_load
      ship_pallets

      success_response("Shipped Load #{load_id}", load_id)
    end

    private

    def ship_load
      id = repo.ship_load(load_id)
      repo.log_status('loads', id, 'SHIPPED', user_name: user_name)

      success_response('ok')
    end

    def ship_pallets
      ids = repo.ship_pallets(pallet_numbers)
      repo.log_multiple_statuses('pallets', ids, 'SHIPPED', user_name: user_name)

      success_response('ok')
    end

    def repo
      @repo ||= LoadRepo.new
    end
  end
end
