# frozen_string_literal: true

module RawMaterialsApp
  class DestroyEmptyBins < BaseService
    # Only one owner bin type pair remove at a time
    # @param [Integer] rmt_container_material_owner_id
    # @param [Integer] location_id
    # @param [Integer] quantity
    # @param [Hash{
    #   [Integer] business_process_id
    #   [Integer] parent_transaction_id
    #   [Integer] asset_type_id
    #   [String] ref_no
    #   [Boolean] is_adhoc
    #   [String] user_name
    # }] opts
    def initialize(rmt_container_material_owner_id, location_id, quantity, opts = {})
      @repo = EmptyBinsRepo.new

      @owner_id = rmt_container_material_owner_id
      @location_id = location_id
      @quantity = quantity

      @opts = opts
      @ref_no = @opts[:ref_no]
      @business_process_id = @opts[:business_process_id]
      @parent_transaction_id = @opts[:parent_transaction_id]
      @asset_type_id = @opts[:asset_transaction_type_id]
      @is_adhoc = @opts[:is_adhoc]
      @user_name = @opts[:user_name]
    end

    def call
      return failed_response('Location does not exist') unless @repo.exists?(:locations, id: @location_id)

      res = @repo.update_empty_bin_location_qty(@owner_id, @quantity, @location_id, add: false)
      return res unless res.success

      res = set_parent_transaction
      return res unless res.success

      create_transaction_item
    end

    private

    def create_transaction_item
      transaction_item_id = @repo.create_empty_bin_transaction_item(
        empty_bin_transaction_id: @parent_transaction_id,
        rmt_container_material_owner_id: @owner_id,
        empty_bin_from_location_id: @location_id,
        quantity_bins: @quantity
      )
      success_response('ok', transaction_item_id)
    end

    def set_parent_transaction
      return ok_response if @parent_transaction_id

      attrs = {
        asset_transaction_type_id: @asset_type_id,
        business_process_id: @business_process_id,
        reference_number: @ref_no,
        is_adhoc: @is_adhoc,
        quantity_bins: @quantity,
        created_by: @opts[:user_name]
      }
      @parent_transaction_id = @repo.create_empty_bin_transaction(attrs)
      ok_response
    end
  end
end
