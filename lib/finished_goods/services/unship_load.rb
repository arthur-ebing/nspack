# frozen_string_literal: true

module FinishedGoodsApp
  class UnshipLoad < BaseService
    attr_reader :repo, :load_id, :pallet_ids, :user_name, :pallet_number

    def initialize(load_id, user_name, pallet_number = nil)
      @repo = LoadRepo.new
      @load_id = load_id
      @pallet_ids = repo.select_values(:pallets, :id, load_id: load_id)
      @pallet_ids = repo.select_values(:pallets, :id, pallet_number: pallet_number) unless pallet_number.nil?
      @pallet_number = pallet_number
      @user_name = user_name
    end

    def call
      if pallet_number.nil?
        unship_load
        unship_pallets
        success_response("Unshipped Load: #{load_id}")
      else
        unship_pallets
        unallocate_pallet
        success_response("Unshipped and unallocated Pallet: #{pallet_number}")
      end
    end

    private

    def unship_load
      attrs = { shipped: false }
      repo.update(:loads, load_id, attrs)
      repo.log_status(:loads, load_id, 'UNSHIPPED', user_name: user_name)

      ok_response
    end

    def unship_location
      location_type_id = repo.get_id(:location_types, location_type_code: 'SITE')
      location_id = repo.get_id(:locations, location_type_id: location_type_id)
      return failed_response('Site location not defined, unable to unship pallet') if location_id.nil?

      success_response('ok', location_id)
    end

    def unship_pallets
      res = unship_location
      return res unless res.success

      attrs = { shipped: false, exit_ref: nil, in_stock: true, location_id: res.instance }
      repo.update(:pallets, pallet_ids, attrs)
      repo.log_multiple_statuses(:pallets, pallet_ids, 'UNSHIPPED', user_name: user_name)

      ok_response
    end

    def unallocate_pallet
      repo.unallocate_pallets(load_id, pallet_number, user_name)
    end
  end
end
