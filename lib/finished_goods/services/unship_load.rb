# frozen_string_literal: true

module FinishedGoodsApp
  class UnshipLoad < BaseService
    attr_reader :load_id, :instance, :user, :pallet_number

    def initialize(load_id, user, pallet_number = nil)
      @load_id = load_id
      @instance = repo.find_load(load_id)
      @pallet_number = pallet_number
      @user = user
    end

    def call
      res = TaskPermissionCheck::Load.call(:unship, load_id)
      return res unless res.success

      unship_pallets

      if pallet_number.nil?
        unship_load
        unship_order
        success_response("Unshipped Load: #{load_id}")
      else
        unallocate_pallet
        success_response("Unshipped and unallocated Pallet: #{pallet_number}")
      end
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def unship_order
      order_ids = DB[:orders_loads].join(:orders, id: :order_id).where(load_id: load_id, shipped: true).select_map(:order_id)
      return if order_ids.empty?

      repo.update(:orders, order_ids, shipped: false)
    end

    def unship_load
      attrs = { shipped: false }
      repo.update(:loads, load_id, attrs)
      repo.log_status(:loads, load_id, 'UNSHIPPED', user_name: user.user_name)

      ok_response
    end

    def unship_pallets # rubocop:disable Metrics/AbcSize
      pallet_ids = if pallet_number.nil?
                     repo.select_values(:pallets, :id, load_id: load_id)
                   else
                     repo.select_values(:pallets, :id, pallet_number: pallet_number)
                   end

      not_shipped = repo.select_values(:pallets, :pallet_number, id: pallet_ids, shipped: false)
      raise Crossbeams::InfoError, "Pallets: #{not_shipped} not shipped." unless not_shipped.empty?

      location_type_id = repo.get_id(:location_types, location_type_code: 'SITE')
      location_id = repo.get_id(:locations, location_type_id: location_type_id)
      raise Crossbeams::InfoError, 'Site location not defined, unable to unship pallet' if location_id.nil?

      attrs = { shipped: false, exit_ref: nil, in_stock: true, location_id: location_id }
      repo.update(:pallets, pallet_ids, attrs)
      repo.log_multiple_statuses(:pallets, pallet_ids, 'UNSHIPPED', user_name: user.user_name)

      ok_response
    end

    def unallocate_pallet
      repo.unallocate_pallets(pallet_number, user)
    end

    def repo
      @repo ||= LoadRepo.new
    end
  end
end
