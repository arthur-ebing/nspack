# frozen_string_literal: true

module RawMaterialsApp
  class BinTippingEbc < BaseService
    # Only one create at a time for the purposes of this service
    # @param [String] ref_no
    # @param [Integer] rmt_container_material_owner_id
    attr_reader :repo, :owner_id, :bin_sets, :opts

    def initialize(ref_no, rmt_container_material_owner_id, opts = {})
      @repo = BinAssetsRepo.new

      @owner_id = rmt_container_material_owner_id
      @bin_sets = [{ rmt_container_material_owner_id: rmt_container_material_owner_id, quantity_bins: 1 }]

      @opts = opts.merge(business_process_id: repo.get_id(:business_processes, process: AppConst::PROCESS_ADHOC_TRANSACTIONS),
                         parent_transaction_id: nil,
                         asset_transaction_type_id: repo.get_id(:asset_transaction_types, transaction_type_code: AppConst::BIN_TIP_ASSET_TRANSACTION_TYPE),
                         rmt_delivery_id: nil,
                         is_adhoc: false,
                         ref_no: ref_no,
                         quantity_bins: bin_sets[:quantity_bins].to_i,
                         user_name: @user.user_name)
    end

    def call
      MoveBinAssets.call({ owner_id: owner_id,
                           quantity: bin_sets[:quantity_bins].to_i,
                           to_location_id: repo.onsite_bin_asset_location_id_for_location_code(AppConst::ONSITE_EMPTY_BIN_LOCATION),
                           from_location_id: repo.onsite_bin_asset_location_id_for_location_code(AppConst::ONSITE_FULL_BIN_LOCATION) },
                         opts.to_h)
    end
  end
end
