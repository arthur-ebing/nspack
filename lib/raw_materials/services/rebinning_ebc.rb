# frozen_string_literal: true

module RawMaterialsApp
  class RebinningEbc < BaseService
    # Only one remove at a time
    # @param [Integer] rmt_container_material_owner_id
    # @param [Hash{
    #   [String] ref_no
    #   [String] user_name
    # }] opts
    def initialize(rmt_container_material_owner_id, opts = {})
      @repo = EmptyBinsRepo.new

      @owner_id = rmt_container_material_owner_id
      @location_id = @repo.onsite_empty_bin_location_id
      @quantity = 1

      @ref_no = @opts[:ref_no]
      @opts = opts.merge(business_process_id: @repo.get_id(:business_processes, process: 'ADHOC_TRANSACTIONS'),
                         parent_transaction_id: nil,
                         asset_transaction_type_id: @repo.get_id(:asset_transaction_types, transaction_type_code: 'REBIN'),
                         is_adhoc: false)
    end

    def call
      DestroyEmptyBins.call(@owner_id, @location_id, @quantity, @opts)
    end
  end
end
