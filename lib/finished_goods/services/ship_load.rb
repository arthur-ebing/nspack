# frozen_string_literal: true

module FinishedGoodsApp
  class ShipLoad < BaseService
    attr_reader :repo, :load_id, :pallet_ids, :user_name, :shipped_at

    def initialize(load_id, user_name)
      @repo = LoadRepo.new
      @load_id = load_id
      @pallet_ids = repo.select_values(:pallets, :id, load_id: load_id)
      @user_name = user_name
      @shipped_at = repo.get(:loads, load_id, :shipped_at) || Time.now
    end

    def call
      repo.transaction do
        res = ship_pallets
        return res unless res.success

        res = ship_load
        return res unless res.success
      end
      success_response("Shipped Load: #{load_id}")
    end

    private

    def ship_load # rubocop:disable Metrics/AbcSize
      load_container_id = repo.get_id(:load_containers, load_id: load_id)
      verified_gross_weight = FinishedGoodsApp::LoadContainerRepo.new.verified_gross_weight_from(load_id: load_id)
      attrs = { verified_gross_weight: verified_gross_weight, verified_gross_weight_date: Time.now }
      repo.update(:load_containers, load_container_id, attrs) unless load_container_id.nil?

      attrs = { shipped: true, shipped_at: shipped_at }
      repo.update(:loads, load_id, attrs)
      repo.log_status(:loads, load_id, 'SHIPPED', user_name: user_name)

      ok_response
    end

    def ship_pallets # rubocop:disable Metrics/AbcSize
      location_to = MasterfilesApp::LocationRepo.new.find_location_by_location_long_code(AppConst::IN_TRANSIT_LOCATION)&.id
      raise Crossbeams::InfoError, "There is no location named #{AppConst::IN_TRANSIT_LOCATION}. Please contact support." if location_to.nil?

      pallet_ids.each do |pallet_id|
        res = MoveStockService.call('PALLET', pallet_id, location_to, 'LOAD_SHIPPED', @load_id)
        return res unless res.success

        attrs = { shipped: true, shipped_at: shipped_at, exit_ref: 'SHIPPED', in_stock: false }
        repo.update(:pallets, pallet_id, attrs)
        repo.log_status(:pallets, pallet_id, 'SHIPPED', user_name: user_name)
      end
      ok_response
    end
  end
end
