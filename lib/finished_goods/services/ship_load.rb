# frozen_string_literal: true

module FinishedGoodsApp
  class ShipLoad < BaseService
    attr_reader :load_id, :pallet_ids, :user_name

    def initialize(load_id, user_name)
      @load_id = load_id
      @pallet_ids = FinishedGoodsApp::LoadRepo.new.find_pallet_ids_from(load_id: load_id)
      @user_name = user_name
    end

    def call
      ship_load
      ship_pallets

      success_response("Shipped Load #{load_id}")
    end

    private

    def ship_load
      repo.ship_load(load_id)
      repo.log_status('loads', load_id, 'SHIPPED', user_name: user_name)

      ok_response
    end

    def ship_pallets
      repo.ship_pallets(pallet_ids)
      repo.log_multiple_statuses('pallets', pallet_ids, 'SHIPPED', user_name: user_name)

      ok_response
    end

    def repo
      @repo ||= LoadRepo.new
    end
  end
end
