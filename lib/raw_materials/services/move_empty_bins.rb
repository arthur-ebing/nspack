# frozen_string_literal: true

module RawMaterialsApp
  class MoveEmptyBins < BaseService
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
    def initialize(owner_id, quantity, to_location_id, from_location_id, opts = {}) # rubocop:disable Metrics/AbcSize
      @repo = EmptyBinsRepo.new

      @to_location_id = to_location_id
      @from_location_id = from_location_id
      @quantity = quantity
      @owner_id = owner_id

      @opts = opts
      @asset_type_id = @opts[:asset_transaction_type_id]
      @ref_no = @opts[:ref_no]
      @parent_transaction_id = @opts[:parent_transaction_id]
      @business_process_id = @opts[:business_process_id]
      @fruit_reception_delivery_id = @opts[:fruit_reception_delivery_id]
      @truck_registration_number = @opts[:truck_registration_number]
      @quantity_bins = @opts[:quantity_bins]
      @is_adhoc = @opts[:is_adhoc]
      @user_name = @opts[:user_name]
    end

    def call
      return failed_response('To location does not exist') unless @repo.exists?(:locations, id: @to_location_id)
      return failed_response('From location does not exist') unless @from_location_id && @repo.exists?(:locations, id: @from_location_id)

      res = move_empty_bins
      return res unless res.success

      res = set_parent_transaction
      return res unless res.success

      create_transaction_item
    end

    private

    def move_empty_bins
      res = @repo.ensure_empty_bin_location(@owner_id, @to_location_id)
      return res unless res.success

      res = @repo.update_empty_bin_location_qty(@owner_id, @quantity, @from_location_id, add: false)
      return failed_response('Insufficient stock at From Location') unless res.success

      @repo.update_empty_bin_location_qty(@owner_id, @quantity, @to_location_id, add: true)
    end

    def create_transaction_item
      transaction_item_id = @repo.create_empty_bin_transaction_item(
        empty_bin_transaction_id: @parent_transaction_id,
        rmt_container_material_owner_id: @owner_id,
        empty_bin_from_location_id: @from_location_id,
        empty_bin_to_location_id: @to_location_id,
        quantity_bins: @quantity
      )
      success_response('ok', transaction_item_id)
    end

    def set_parent_transaction
      return ok_response if @parent_transaction_id

      attrs = {
        asset_transaction_type_id: @asset_type_id,
        empty_bin_to_location_id: @to_location_id,
        business_process_id: @business_process_id,
        reference_number: @ref_no,
        fruit_reception_delivery_id: @fruit_reception_delivery_id,
        truck_registration_number: @truck_registration_number,
        quantity_bins: @quantity_bins,
        is_adhoc: @is_adhoc,
        created_by: @user_name
      }
      @parent_transaction_id = @repo.create_empty_bin_transaction(attrs)
      ok_response
    end
  end
end
