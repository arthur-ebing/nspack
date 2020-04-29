# frozen_string_literal: true

module RawMaterialsApp
  class Rebinning < BaseService
    # Only one remove at a time
    # @param [Integer] rmt_container_material_owner_id
    # @param [Integer] location_id
    # @param [Integer] quantity
    # @param [Hash{
    #   [String] ref_no
    #   [String] user_name
    # }] opts
    def initialize(rmt_container_material_owner_id, location_id, quantity, opts = {})
      @repo = EmptyBinsRepo.new

      @owner_id = rmt_container_material_owner_id
      @location_id = location_id
      @quantity = quantity

      @ref_no = @opts.fetch(:ref_no)
      @opts = opts.merge(business_process_id: @repo.get_id(:business_processes, process: 'ADHOC_TRANSACTIONS'),
                         parent_transaction_id: nil,
                         asset_type_id: @repo.get_id(:asset_transaction_types, transaction_type_code: 'REBIN'),
                         is_adhoc: false)
    end

    def call
      DestroyEmptyBins.call(@owner_id, @location_id, @quantity, @opts)
    end
  end
end
