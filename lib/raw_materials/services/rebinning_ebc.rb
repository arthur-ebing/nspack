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
      @repo = BinAssetsRepo.new

      @owner_id = rmt_container_material_owner_id
      @from_location_id = @repo.onsite_bin_asset_location_id_for_location_code(AppConst::ONSITE_EMPTY_BIN_LOCATION)
      @to_location_id = @repo.onsite_bin_asset_location_id_for_location_code(AppConst::ONSITE_FULL_BIN_LOCATION)
      @quantity = 1
      @ref_no = @opts[:ref_no]
      @opts = opts.merge(business_process_id: @repo.get_id(:business_processes, process: AppConst::PROCESS_ADHOC_TRANSACTIONS),
                         parent_transaction_id: nil,
                         asset_transaction_type_id: @repo.get_id(:asset_transaction_types, transaction_type_code: 'REBIN'),
                         is_adhoc: false,
                         ref_no: nil,
                         quantity_bins: @quantity,
                         user_name: @user.user_name)
    end

    def call
      MoveBinAssets.call(@owner_id, @quantity, @to_location_id, @from_location_id, @opts)
    end
  end
end
