# frozen_string_literal: true

module FinishedGoodsApp
  class UnshipLoad < BaseService
    attr_reader :load_id, :pallet_numbers, :user_name

    def initialize(load_id, user_name, pallet_number = nil)
      @load_id = load_id
      @pallet_numbers = [pallet_number]
      @unship_pallet = true unless pallet_number.nil?
      @pallet_numbers = FinishedGoodsApp::LoadRepo.new.find_pallet_numbers_from(load_id: load_id) if pallet_number.nil?
      @user_name = user_name
    end

    def call
      unship_load
      unship_pallets

      success_response("Unshipped Load #{load_id}", load_id)
    end

    private

    def unship_load
      id = repo.unship_load(load_id)
      repo.log_status('loads', id, 'UNSHIPPED', user_name: user_name)

      success_response('ok')
    end

    def unship_pallets
      ids = repo.unship_pallets(pallet_numbers)
      repo.log_multiple_statuses('pallets', ids, 'UNSHIPPED', user_name: user_name)

      success_response('ok')
    end

    def repo
      @repo ||= LoadRepo.new
    end
  end
end
