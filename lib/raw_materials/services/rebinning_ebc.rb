# frozen_string_literal: true

module RawMaterialsApp
  class RebinningEbc < BaseService
    # Only one remove at a time
    # @param [Integer] rmt_container_material_owner_id
    # @param [Hash{
    #   [String] ref_no
    #   [String] user_name
    # }] opts
    attr_reader :repo, :owner_id, :quantity, :opts

    def initialize(rmt_container_material_owner_id, opts = {})
      @repo = BinAssetsRepo.new

      @owner_id = rmt_container_material_owner_id
      @quantity = 1
      @ref_no = @opts[:ref_no]
      @opts = opts.merge(business_process_id: repo.get_id(:business_processes, process: AppConst::PROCESS_ADHOC_TRANSACTIONS),
                         parent_transaction_id: nil,
                         asset_transaction_type_id: repo.get_id(:asset_transaction_types, transaction_type_code: AppConst::REBIN_ASSET_TRANSACTION_TYPE),
                         is_adhoc: false,
                         ref_no: nil,
                         quantity_bins: quantity,
                         user_name: @user.user_name)
    end

    def call
      MoveBinAssets.call({ owner_id: owner_id,
                           quantity: quantity,
                           to_location_id: repo.onsite_bin_asset_location_id_for_location_code(AppConst::ONSITE_FULL_BIN_LOCATION),
                           from_location_id: repo.onsite_bin_asset_location_id_for_location_code(AppConst::ONSITE_EMPTY_BIN_LOCATION) },
                         opts.to_h)
    end
  end
end
