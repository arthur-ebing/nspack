# frozen_string_literal: true

module RawMaterialsApp
  class EmptyBinsRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :empty_bin_transactions,
                     label: :truck_registration_number,
                     value: :id,
                     no_active_check: true,
                     order_by: :truck_registration_number

    crud_calls_for :empty_bin_transactions, name: :empty_bin_transaction, wrapper: EmptyBinTransaction

    build_for_select :empty_bin_transaction_items,
                     label: :id,
                     value: :id,
                     no_active_check: true,
                     order_by: :id

    crud_calls_for :empty_bin_transaction_items, name: :empty_bin_transaction_item, wrapper: EmptyBinTransactionItem

    build_for_select :business_processes,
                     label: :process,
                     value: :id,
                     no_active_check: true,
                     order_by: :id

    build_for_select :rmt_container_material_owners,
                     label: :rmt_material_owner_party_role_id,
                     value: :rmt_material_owner_party_role_id,
                     no_active_check: true,
                     order_by: :rmt_material_owner_party_role_id

    def find_empty_bin_transaction(id)
      find_with_association(:empty_bin_transactions, id,
                            parent_tables: [{ parent_table: :asset_transaction_types,
                                              foreign_key: :asset_transaction_type_id,
                                              columns: %i[transaction_type_code],
                                              flatten_columns: { transaction_type_code: :transaction_type_code } },
                                            { parent_table: :locations,
                                              foreign_key: :empty_bin_to_location_id,
                                              columns: %i[location_long_code],
                                              flatten_columns: { location_long_code: :location_long_code } },
                                            { parent_table: :business_processes,
                                              foreign_key: :business_process_id,
                                              columns: %i[process],
                                              flatten_columns: { process: :process } }],
                            wrapper: EmptyBinTransaction)
    end

    def for_select_empty_bin_owners
      for_select_rmt_container_material_owners.uniq.map { |r| [DB['select fn_party_role_name(?)', r].first[:fn_party_role_name], r] }
    end

    def for_select_empty_bin_locations
      location_type_id = DB[:location_types].where(location_type_code: AppConst::LOCATION_TYPES_EMPTY_BIN).get(:id)
      MasterfilesApp::LocationRepo.new.for_select_locations(where: { location_type_id: location_type_id })
    end

    def for_select_available_empty_bin_locations
      available_ids = DB[:empty_bin_locations].select_map(:location_id)
      location_type_id = DB[:location_types].where(location_type_code: AppConst::LOCATION_TYPES_EMPTY_BIN).get(:id)
      MasterfilesApp::LocationRepo.new.for_select_locations(where: { location_type_id: location_type_id, id: available_ids })
    end

    def find_owner_bin_type(owner_id, type_id)
      id = get_id(:rmt_container_material_owners,
                  rmt_material_owner_party_role_id: owner_id,
                  rmt_container_material_type_id: type_id)
      find_with_association(:rmt_container_material_owners, id,
                            parent_tables: [{ parent_table: :rmt_container_material_types,
                                              foreign_key: :rmt_container_material_type_id,
                                              columns: %i[container_material_type_code],
                                              flatten_columns: { container_material_type_code: :container_material_type_code } }],
                            lookup_functions: [{ function: :fn_party_role_name,
                                                 args: [owner_id],
                                                 col_name: :owner_party_name }],
                            wrapper: OwnerBinType)
    end

    def onsite_empty_bin_location_id
      DB[:locations].where(
        location_long_code: AppConst::ONSITE_EMPTY_BIN_LOCATION
      ).join(:location_types, id: :location_type_id).where(
        location_type_code: AppConst::LOCATION_TYPES_EMPTY_BIN
      ).get(Sequel[:locations][:id])
    end

    def location_repo
      @location_repo ||= MasterfilesApp::LocationRepo.new
    end

    # @param [Symbol] mode
    def asset_transaction_type_id_for_mode(mode)
      DB[:asset_transaction_types].where(transaction_type_code: AppConst::ASSET_TRANSACTION_TYPES[mode]).get(:id)
    end

    def truck_registration_number_for_delivery(delivery_id)
      DB[:rmt_deliveries].where(id: delivery_id).get(:truck_registration_number)
    end

    def options_for_rmt_container_material_types(owner_id)
      type_ids = DB[:rmt_container_material_owners].where(rmt_material_owner_party_role_id: owner_id).select_map(:rmt_container_material_type_id)
      DB[:rmt_container_material_types].where(id: type_ids).map { |r| [r[:container_material_type_code], r[:id]] }
    end

    def create_empty_bin_location_ids(bin_sets, to_location_id)
      bin_sets.each do |set|
        id = get_id_or_create(:empty_bin_locations,
                              rmt_container_material_owner_id: set[:rmt_container_material_owner_id],
                              location_id: to_location_id)
        update(:empty_bin_locations, id, quantity: set[:qty])
      end
      ok_response
    end

    def create_empty_bin_transaction(attrs)
      create(:empty_bin_transactions, attrs)
    end

    # @param [Integer] owner_id: rmt_container_material_owner_id
    # @param [Integer] quantity
    # @param [Integer] location_id
    # @param [Bool] add: add or subtract
    def update_empty_bin_location_qty(owner_id, quantity, location_id, add: false) # rubocop:disable Metrics/AbcSize
      location = DB[:empty_bin_locations].where(rmt_container_material_owner_id: owner_id,
                                                location_id: location_id)
      return failed_response('Empty bin location does not exist') unless location.first

      existing_qty = location.get(:quantity) || AppConst::BIG_ZERO
      qty = add ? (existing_qty + quantity) : (existing_qty - quantity)
      if qty.positive?
        location.update(quantity: qty)
        success_response('updated successfully')
      elsif qty.zero?
        location.delete
        success_response('Empty Bin Location removed')
      else
        failed_response('can not update with negative amount', qty)
      end
    end

    def ensure_empty_bin_location(owner_id, to_location_id)
      empty_bin_location_id = get_id_or_create(:empty_bin_locations,
                                               rmt_container_material_owner_id: owner_id,
                                               location_id: to_location_id)
      return failed_response('Could not find or create empty bin location') unless empty_bin_location_id

      success_response('ok')
    end

    def validate_empty_bin_location_quantities(from_location_id, bin_sets = []) # rubocop:disable Metrics/AbcSize
      bin_sets.each do |set|
        qty = empty_bin_location_qty(set[:rmt_container_material_owner_id], set[:rmt_container_material_type_id], from_location_id)
        next if qty >= set[:quantity_bins].to_i

        owner_bin_type = find_owner_bin_type(set[:rmt_container_material_owner_id], set[:rmt_container_material_type_id])
        bin_type = owner_bin_type.container_material_type_code
        location_code = DB[:locations].where(id: from_location_id).get(:location_long_code)
        message = "Insufficient amount of #{bin_type} from #{owner_bin_type.owner_party_name} at #{location_code}: #{qty} Available"
        return validation_failed_response(OpenStruct.new(messages: { base: [message] }, instance: hash))
      end
      success_response('ok')
    end

    def empty_bin_location_qty(owner_id, type_id, location_id)
      DB[:empty_bin_locations].where(
        rmt_container_material_owner_id: DB[:rmt_container_material_owners].where(
          rmt_material_owner_party_role_id: owner_id,
          rmt_container_material_type_id: type_id
        ).get(:id),
        location_id: location_id
      ).get(:quantity) || AppConst::BIG_ZERO
    end

    def get_applicable_transaction_item_ids(loc_id)
      from_ids = DB[:empty_bin_transaction_items].where(empty_bin_from_location_id: loc_id).select_map(:id)
      to_ids = DB[:empty_bin_transaction_items].where(empty_bin_to_location_id: loc_id).select_map(:id)
      item_ids = (from_ids || []) + (to_ids || [])
      success_response('ok', item_ids.sort.uniq)
    end
  end
end
