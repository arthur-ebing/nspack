# frozen_string_literal: true

module FinishedGoodsApp
  class AllocatePallets < BaseService
    attr_reader :load_id, :pallet_numbers, :user_name

    def initialize(load_id, pallet_numbers, user)
      @load_id = load_id
      @pallet_numbers = pallet_numbers
      @user_name = user.user_name
    end

    def call
      res = allocate_pallets
      raise Crossbeams::InfoError, res.message unless res.success
    end

    private

    def allocate_pallets # rubocop:disable Metrics/AbcSize
      pallet_ids = repo.select_values(:pallets, :id, pallet_number: pallet_numbers)
      return ok_response if pallet_ids.empty?

      repo.update(:pallets, pallet_ids, load_id: load_id, allocated: true, allocated_at: Time.now)
      repo.log_multiple_statuses(:pallets, pallet_ids, 'ALLOCATED', user_name: user_name)

      # updates load status allocated
      repo.update(:loads, load_id, allocated: true, allocated_at: Time.now)
      repo.log_status(:loads, load_id, 'ALLOCATED', user_name: user_name)

      ok_response
    end

    def repo
      @repo ||= LoadRepo.new
    end
  end
end
