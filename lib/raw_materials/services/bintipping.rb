# frozen_string_literal: true

module RawMaterialsApp
  class BinTipping < BaseService
    # Only one create at a time for the purposes of this service
    # @param [Integer] to_location_id
    # @param [String] ref_no
    # @param [Integer] rmt_container_material_owner_id
    # @param [Integer] quantity
    def initialize(to_location_id, ref_no, rmt_container_material_owner_id, quantity)
      @repo = EmptyBinsRepo.new

      @asset_type_id = @repo.get_id(:asset_transaction_types, transaction_type_code: 'BIN_TIP')
      @to_location_id = to_location_id
      @ref_no = ref_no
      @bin_sets = [{ rmt_container_material_owner_id: rmt_container_material_owner_id, quantity_bins: quantity }]

      @opts = opts.merge(business_process_id: @repo.get_id(:business_processes, process: 'ADHOC_TRANSACTIONS'),
                         parent_transaction_id: nil,
                         rmt_delivery_id: nil,
                         is_adhoc: false)
    end

    def call
      CreateEmptyBins.call(@asset_type_id, @to_location_id, @ref_no, @bin_sets, @opts)
    end
  end
end
