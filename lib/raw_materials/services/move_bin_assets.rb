# frozen_string_literal: true

module RawMaterialsApp
  class MoveBinAssets < BaseService
    # @param [Integer] owner_id (rmt_container_material_owner_id) Only one pair per move
    # @param [Integer] quantity, Integer
    # @param [Integer] to_location_id
    # @param [Integer] from_location_id
    # @param [Hash] opts {
    #   asset_transaction_type_id
    #   parent_transaction_id
    #   business_process_id
    #   ref_no
    #   is_adhoc
    #   user_name
    attr_reader :repo, :owner_id, :quantity, :to_location_id, :from_location_id, :opts, :create_error_log

    def initialize(params, opts = {}, create_error_log = false)
      @repo = BinAssetsRepo.new

      @to_location_id = params[:to_location_id]
      @from_location_id = params[:from_location_id]
      @quantity = params[:quantity]
      @owner_id = params[:owner_id]
      @opts = opts
      @create_error_log = create_error_log
    end

    def call
      return failed_response("To location does not exist - id: #{to_location_id}.") unless repo.exists?(:locations, id: to_location_id)
      return failed_response("From location does not exist - id: #{from_location_id}.") unless from_location_id && repo.exists?(:locations, id: from_location_id)

      res = move_bin_assets
      return res unless res.success

      res = set_parent_transaction
      return res unless res.success

      create_transaction_item
    end

    private

    def move_bin_assets # rubocop:disable Metrics/AbcSize
      res = repo.ensure_bin_asset_location(owner_id, from_location_id)
      return res unless res.success

      res = repo.ensure_bin_asset_location(owner_id, to_location_id)
      return res unless res.success

      res = repo.update_bin_asset_location_qty(owner_id, quantity, from_location_id, add: false)
      unless res.success
        return failed_response('Insufficient stock at From Location') unless create_error_log

        create_bin_asset_move_error_log
      end

      repo.update_bin_asset_location_qty(owner_id, quantity, to_location_id, add: true)
    end

    def create_transaction_item
      transaction_item_id = repo.create_bin_asset_transaction_item(
        bin_asset_transaction_id: opts[:parent_transaction_id],
        rmt_container_material_owner_id: owner_id,
        bin_asset_from_location_id: from_location_id,
        bin_asset_to_location_id: to_location_id,
        quantity_bins: quantity
      )
      success_response('ok', transaction_item_id)
    end

    def set_parent_transaction # rubocop:disable Metrics/AbcSize
      return ok_response if opts[:parent_transaction_id]

      attrs = {
        asset_transaction_type_id: opts[:asset_transaction_type_id],
        bin_asset_to_location_id: to_location_id,
        business_process_id: opts[:business_process_id],
        reference_number: opts[:ref_no],
        fruit_reception_delivery_id: opts[:fruit_reception_delivery_id].nil_or_empty? ? nil : opts[:fruit_reception_delivery_id],
        truck_registration_number: opts[:truck_registration_number],
        quantity_bins: opts[:quantity_bins],
        is_adhoc: opts[:is_adhoc],
        created_by: opts[:user_name],
        changes_made: opts[:changes_made]
      }
      opts[:parent_transaction_id] = repo.create_bin_asset_transaction(attrs)
      ok_response
    end

    def create_bin_asset_move_error_log
      repo.create_bin_asset_move_error_log({ rmt_container_material_owner_id: owner_id,
                                             location_id: from_location_id,
                                             quantity: quantity })
    end
  end
end
