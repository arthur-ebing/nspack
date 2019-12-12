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
      res = ship_pallets
      return res unless res.success

      res = ship_load
      return res unless res.success

      success_response("Shipped Load #{load_id}")
    end

    private

    def ship_load
      repo.ship_load(load_id)
      repo.log_status(:loads, load_id, 'SHIPPED', user_name: user_name)

      ok_response
    end

    def ship_pallets # rubocop:disable Metrics/AbcSize
      location_to = MasterfilesApp::LocationRepo.new.find_location_by_location_long_code(AppConst::IN_TRANSIT_LOCATION)&.id
      raise Crossbeams::InfoError, "There is no location named #{AppConst::IN_TRANSIT_LOCATION}. Please contact support." if location_to.nil?

      pallet_ids.each do |pallet_id|
        res = MoveStockService.call('PALLET', pallet_id, location_to, 'LOAD_SHIPPED', @load_id)
        return res unless res.success
      end

      repo.ship_pallets(pallet_ids)
      repo.log_multiple_statuses(:pallets, pallet_ids, 'SHIPPED', user_name: user_name)

      ok_response
    end

    def repo
      @repo ||= LoadRepo.new
    end
  end
end
