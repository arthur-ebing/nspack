# frozen_string_literal: true

module RawMaterialsApp
  class BinTippingEbc < BaseService
    # Only one create at a time for the purposes of this service
    # @param [String] ref_no
    # @param [Integer] rmt_container_material_owner_id
    def initialize(ref_no, rmt_container_material_owner_id)
      @repo = BinAssetsRepo.new

      @owner_id = rmt_container_material_owner_id
      @asset_type_id = @repo.get_id(:asset_transaction_types, transaction_type_code: 'BIN_TIP')
      @from_location_id = @repo.onsite_bin_asset_location_id_for_location_code(AppConst::ONSITE_FULL_BIN_LOCATION)
      @to_location_id = @repo.onsite_bin_asset_location_id_for_location_code(AppConst::ONSITE_EMPTY_BIN_LOCATION)
      @ref_no = ref_no
      @bin_sets = [{ rmt_container_material_owner_id: rmt_container_material_owner_id, quantity_bins: 1 }]

      @opts = opts.merge(business_process_id: @repo.get_id(:business_processes, process: AppConst::PROCESS_ADHOC_TRANSACTIONS),
                         parent_transaction_id: nil,
                         rmt_delivery_id: nil,
                         is_adhoc: false,
                         ref_no: ref_no,
                         quantity_bins: @bin_sets[:quantity_bins].to_i,
                         user_name: @user.user_name)
    end

    def call
      MoveBinAssets.call(@owner_id, @bin_sets[:quantity_bins].to_i, @to_location_id, @from_location_id, @opts)
    end
  end
end
