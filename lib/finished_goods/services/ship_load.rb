# frozen_string_literal: true

module FinishedGoodsApp
  class ShipLoad < BaseService
    attr_reader :load_id, :instance, :user, :shipped_at, :repo

    def initialize(load_id, user)
      @repo = LoadRepo.new
      @load_id = load_id
      @instance = repo.find_load(load_id)
      @user = user
      @shipped_at = repo.get(:loads, load_id, :shipped_at) || Time.now
    end

    def call
      res = TaskPermissionCheck::Load.call(:ship, load_id)
      return res unless res.success

      ship_pallets
      ship_load
      ship_order

      success_response("Shipped Load: #{load_id}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def ship_order
      order_ids = repo.select_values(:orders_loads, :order_id, load_id: load_id)
      return if order_ids.empty?

      order_ids.each do |order_id|
        next unless TaskPermissionCheck::Order.call(:ship, order_id).success

        repo.update(:orders, order_id, shipped: true)
      end
    end

    def ship_load # rubocop:disable Metrics/AbcSize
      load_container_id = repo.get_id(:load_containers, load_id: load_id)
      verified_gross_weight = LoadContainerRepo.new.calculate_verified_gross_weight(load_container_id)
      attrs = { verified_gross_weight: verified_gross_weight,
                verified_gross_weight_date: Time.now }
      repo.update(:load_containers, load_container_id, attrs) unless load_container_id.nil?

      attrs = { shipped: true, shipped_at: shipped_at }
      repo.update(:loads, load_id, attrs)
      repo.log_status(:loads, load_id, 'SHIPPED', user_name: user.user_name)

      ok_response
    end

    def ship_pallets # rubocop:disable Metrics/AbcSize
      location_to = MasterfilesApp::LocationRepo.new.find_location_by_location_long_code(AppConst::IN_TRANSIT_LOCATION)&.id
      raise Crossbeams::InfoError, "There is no location named #{AppConst::IN_TRANSIT_LOCATION}. Please contact support." if location_to.nil?

      pallet_ids = repo.select_values(:pallets, :id, load_id: load_id)
      pallet_ids.each do |pallet_id|
        res = MoveStockService.call('PALLET', pallet_id, location_to, 'LOAD_SHIPPED', @load_id)
        raise Crossbeams::InfoError, res.message unless res.success

        attrs = { shipped: true, shipped_at: shipped_at, exit_ref: 'SHIPPED', in_stock: false }
        repo.update(:pallets, pallet_id, attrs)
        repo.log_status(:pallets, pallet_id, 'SHIPPED', user_name: user.user_name)
      end
      ok_response
    end
  end
end
