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
        @pallet_ids = FinishedGoodsApp::LoadRepo.new.find_pallet_ids_from(pallet_numbers: pallet_number)
      end
      @user_name = user_name
    end

    def call
      if pallet_number.nil?
        unship_load
        unship_pallets

        success_response("Unshipped Load #{load_id}")
      else
        unship_unallocate_pallet

        success_response("Unshipped and Unallocated Pallet #{pallet_number}")
      end
    end

    private

    def unship_load
      repo.unship_load(load_id)
      repo.log_status('loads', load_id, 'UNSHIPPED', user_name: user_name)

      ok_response
    end

    def unship_pallets
      repo.unship_pallets(pallet_ids)
      repo.log_multiple_statuses('pallets', pallet_ids, 'UNSHIPPED', user_name: user_name)

      ok_response
    end

    def unship_unallocate_pallet
      repo.unship_pallets(pallet_ids)
      repo.log_multiple_statuses('pallets', pallet_ids, 'UNSHIPPED', user_name: user_name)
      repo.unallocate_pallets(load_id, pallet_ids, user_name)

      ok_response
    end

    def repo
      @repo ||= LoadRepo.new
    end
  end
end
