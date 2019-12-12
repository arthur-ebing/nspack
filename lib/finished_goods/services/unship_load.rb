# frozen_string_literal: true

module FinishedGoodsApp
  class UnshipLoad < BaseService
    attr_reader :load_id, :pallet_ids, :user_name, :pallet_number

    def initialize(load_id, user_name, pallet_number = nil)
      @load_id = load_id
      if pallet_number.nil?
        @pallet_ids = FinishedGoodsApp::LoadRepo.new.find_pallet_ids_from(load_id: load_id)
      else
        @pallet_number = pallet_number
        @pallet_ids = FinishedGoodsApp::LoadRepo.new.find_pallet_ids_from(pallet_number: pallet_number)
      end
      @user_name = user_name
    end

    def call
      if pallet_number.nil?
        unship_load
        unship_pallets
        success_response("Unshipped Load:#{load_id}")
      else
        unship_pallets
        unallocate_pallet
        success_response("Unshipped and Unallocated Pallet:#{pallet_number}")
      end
    end

    private

    def unship_load
      attrs = { shipped: false, shipped_at: nil }
      repo.update(:loads, load_id, attrs)
      repo.log_status(:loads, load_id, 'UNSHIPPED', user_name: user_name)

      ok_response
    end

    def unship_location
      location_type_id = repo.where_hash(:location_types, location_type_code: 'SITE')[:id]
      location_id = repo.where_hash(:locations, location_type_id: location_type_id)[:id]
      return failed_response('Site location not defined, unable to unship pallet') if location_id.nil?

      success_response('ok', location_id)
    end

    def unship_pallets
      res = unship_location
      return res unless res.success

      attrs = { shipped: false, shipped_at: nil, exit_ref: nil, in_stock: true, location_id: res.instance }
      repo.update(:pallets, pallet_ids, attrs)
      repo.log_multiple_statuses(:pallets, pallet_ids, 'UNSHIPPED', user_name: user_name)

      ok_response
    end

    def unallocate_pallet
      repo.unallocate_pallets(load_id, pallet_ids, user_name)
    end

    def repo
      @repo ||= LoadRepo.new
    end
  end
end
