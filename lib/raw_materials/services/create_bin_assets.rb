# frozen_string_literal: true

module RawMaterialsApp
  class CreateBinAssets < BaseService
    # @param [Integer] total_quantity (Total qty bins in parent transaction)
    # @param [Integer] to_location_id
    # @param [String] ref_no
    # @param [Array] bin_sets: Array of hashes{
    #   [Integer] rmt_container_material_owner_id
    #   [Integer] quantity_bins
    # }
    # @param [Hash{
    #   [Integer] business_process_id
    #   [Integer] asset_transaction_type_id
    #   [Integer] parent_transaction_id
    #   [Integer] rmt_delivery_id
    #   [Boolean] is_adhoc
    # }] opts
    #
    def initialize(total_quantity, to_location_id, ref_no, bin_sets = [], opts = {})
      @repo = BinAssetsRepo.new
      @quantity_bins = total_quantity
      @to_location_id = to_location_id
      @ref_no = ref_no

      @opts = opts
      @business_process_id = @opts[:business_process_id]
      @asset_type_id = @opts[:asset_transaction_type_id]
      @parent_transaction_id = @opts[:parent_transaction_id]
      # @delivery_id = @opts[:rmt_delivery_id]
      # @truck_reg_no = @repo.find(:rmt_deliveries, RmtDelivery, @delivery_id)&.truck_registration_number if @delivery_id
      @is_adhoc = @opts[:is_adhoc]
      @bin_sets = bin_sets
    end

    def call
      return failed_response('To location does not exist') unless @repo.exists?(:locations, id: @to_location_id)

      res = @repo.create_bin_asset_location_ids(@bin_sets, @to_location_id)
      return res unless res.success

      res = set_parent_transaction
      return res unless res.success

      create_bin_asset_transaction_items(parent_transaction_id: @parent_transaction_id, transaction_item_ids: [])
    end

    private

    def create_bin_asset_transaction_items(response_hash)
      @bin_sets.each do |set|
        owner_id = @repo.get_owner_id(set)
        transaction_item_id = @repo.create_bin_asset_transaction_item(
          bin_asset_transaction_id: @parent_transaction_id,
          rmt_container_material_owner_id: owner_id,
          bin_asset_from_location_id: nil,
          bin_asset_to_location_id: @to_location_id,
          quantity_bins: set[:quantity_bins]
        )
        response_hash[:transaction_item_ids] << transaction_item_id
      end
      success_response('ok', response_hash)
    end

    def set_parent_transaction
      return ok_response if @parent_transaction_id

      attrs = {
        asset_transaction_type_id: @asset_type_id,
        bin_asset_to_location_id: @to_location_id,
        business_process_id: @business_process_id,
        # fruit_reception_delivery_id: @delivery_id,
        # truck_registration_number: @truck_reg_no,
        reference_number: @ref_no,
        is_adhoc: @is_adhoc,
        quantity_bins: @quantity_bins,
        created_by: @opts[:user_name]
      }
      @parent_transaction_id = @repo.create_bin_asset_transaction(attrs)
      ok_response
    end
  end
end
