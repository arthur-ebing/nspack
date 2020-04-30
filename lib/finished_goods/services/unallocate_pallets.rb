# frozen_string_literal: true

module FinishedGoodsApp
  class UnallocatePallets < BaseService
    attr_reader :load_id, :pallet_numbers, :user_name

    def initialize(load_id, pallet_numbers, user)
      @load_id = load_id
      @pallet_numbers = pallet_numbers
      @user_name = user.user_name
    end

    def call
      res = unallocate_pallets
      raise Crossbeams::InfoError, res.message unless res.success
    end

    private

    def unallocate_pallets # rubocop:disable Metrics/AbcSize
      pallet_ids = repo.select_values(:pallets, :id, pallet_number: pallet_numbers)
      return ok_response if pallet_ids.empty?

      repo.update(:pallets, pallet_ids, load_id: nil, allocated: false)
      repo.log_multiple_statuses(:pallets, pallet_ids, 'UNALLOCATED', user_name: user_name)

      # log status for loads where all pallets have been unallocated
      unless repo.exists?(:pallets, load_id: load_id)
        repo.update(:loads, load_id, allocated: false)
        repo.log_multiple_statuses(:loads, load_id, 'UNALLOCATED', user_name: user_name)
      end

      ok_response
    end

    def repo
      @repo ||= LoadRepo.new
    end
  end
end
