# frozen_string_literal: true

module RawMaterialsApp
  class DestroyBinAssets < BaseService
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
    attr_reader :repo, :owner_id, :location_id, :quantity, :opts, :create_error_log

    def initialize(params, opts = {}, create_error_log = false)
      @repo = BinAssetsRepo.new

      @owner_id = params[:owner_id]
      @location_id = params[:location_id]
      @quantity = params[:quantity]
      @opts = opts
      @create_error_log = create_error_log
    end

    def call
      return failed_response('Location does not exist') unless repo.exists?(:locations, id: location_id)

      res = repo.update_bin_asset_location_qty(owner_id, quantity, location_id, add: false)
      unless res.success
        return res unless create_error_log

        create_bin_asset_move_error_log
      end

      res = set_parent_transaction
      return res unless res.success

      create_transaction_item
    end

    private

    def create_transaction_item
      transaction_item_id = repo.create_bin_asset_transaction_item(
        bin_asset_transaction_id: opts[:parent_transaction_id],
        rmt_container_material_owner_id: owner_id,
        bin_asset_from_location_id: location_id,
        quantity_bins: quantity
      )
      success_response('ok', transaction_item_id)
    end

    def set_parent_transaction # rubocop:disable Metrics/AbcSize
      return ok_response if opts[:parent_transaction_id]

      attrs = {
        asset_transaction_type_id: opts[:asset_transaction_type_id],
        business_process_id: opts[:business_process_id],
        reference_number: opts[:ref_no],
        is_adhoc: opts[:is_adhoc],
        quantity_bins: quantity,
        created_by: opts[:user_name]
      }
      opts[:parent_transaction_id] = repo.create_bin_asset_transaction(attrs)
      ok_response
    end

    def create_bin_asset_move_error_log
      repo.create_bin_asset_move_error_log({ rmt_container_material_owner_id: owner_id,
                                             location_id: location_id,
                                             quantity: quantity })
    end
  end
end
