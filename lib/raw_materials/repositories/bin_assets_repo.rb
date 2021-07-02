# frozen_string_literal: true

module RawMaterialsApp
  class BinAssetsRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :bin_asset_transactions,
                     label: :truck_registration_number,
                     value: :id,
                     no_active_check: true,
                     order_by: :truck_registration_number

    crud_calls_for :bin_asset_transactions, name: :bin_asset_transaction, wrapper: BinAssetTransaction

    build_for_select :bin_asset_transaction_items,
                     label: :id,
                     value: :id,
                     no_active_check: true,
                     order_by: :id

    crud_calls_for :bin_asset_transaction_items, name: :bin_asset_transaction_item, wrapper: BinAssetTransactionItem

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

    def find_bin_asset_transaction(id)
      find_with_association(:bin_asset_transactions, id,
                            parent_tables: [{ parent_table: :asset_transaction_types,
                                              foreign_key: :asset_transaction_type_id,
                                              columns: %i[transaction_type_code],
                                              flatten_columns: { transaction_type_code: :transaction_type_code } },
                                            { parent_table: :locations,
                                              foreign_key: :bin_asset_to_location_id,
                                              columns: %i[location_long_code],
                                              flatten_columns: { location_long_code: :location_long_code } },
                                            { parent_table: :business_processes,
                                              foreign_key: :business_process_id,
                                              columns: %i[process],
                                              flatten_columns: { process: :process } }],
                            wrapper: BinAssetTransaction)
    end

    def for_select_bin_asset_owners
      for_select_rmt_container_material_owners.uniq.map { |r| [DB['select fn_party_role_name(?)', r].first[:fn_party_role_name], r] }
    end

    def for_select_bin_asset_locations
      location_type_id = DB[:location_types].where(location_type_code: AppConst::LOCATION_TYPES_BIN_ASSET).get(:id)
      MasterfilesApp::LocationRepo.new.for_select_locations(where: { location_type_id: location_type_id })
    end

    def for_select_available_bin_asset_locations
      available_ids = DB[:bin_asset_locations].select_map(:location_id)
      location_type_id = DB[:location_types].where(location_type_code: AppConst::LOCATION_TYPES_BIN_ASSET).get(:id)
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

    def onsite_bin_asset_location_id_for_location_code(location_code)
      DB[:locations].where(
        location_long_code: location_code
      ).join(:location_types, id: :location_type_id).where(
        location_type_code: AppConst::LOCATION_TYPES_BIN_ASSET
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

    def get_owner_id(set)
      get_id(:rmt_container_material_owners,
             rmt_material_owner_party_role_id: set[:rmt_material_owner_party_role_id],
             rmt_container_material_type_id: set[:rmt_container_material_type_id])
    end

    def create_bin_asset_location_ids(bin_sets, to_location_id)
      bin_sets.each do |set|
        id = get_id_or_create(:bin_asset_locations,
                              rmt_container_material_owner_id: get_owner_id(set),
                              location_id: to_location_id)
        update(:bin_asset_locations, id, quantity: set[:quantity_bins])
      end
      ok_response
    end

    def create_bin_asset_transaction(attrs)
      create(:bin_asset_transactions, attrs)
    end

    # @param [Integer] owner_id: rmt_container_material_owner_id
    # @param [Integer] quantity
    # @param [Integer] location_id
    # @param [Bool] add: add or subtract
    def update_bin_asset_location_qty(owner_id, quantity, location_id, add: false)
      location = DB[:bin_asset_locations].where(rmt_container_material_owner_id: owner_id,
                                                location_id: location_id)
      return failed_response('Bin Asset location does not exist') unless location.first

      existing_qty = location.get(:quantity) || AppConst::BIG_ZERO
      qty = add ? (existing_qty + quantity) : (existing_qty - quantity)
      if qty.positive?
        location.update(quantity: qty)
        success_response('updated successfully')
      elsif qty.zero?
        location.delete
        success_response('Bin Asset Location removed')
      else
        failed_response('can not update with negative amount', qty)
      end
    end

    def ensure_bin_asset_location(owner_id, to_location_id)
      bin_asset_location_id = get_id_or_create(:bin_asset_locations,
                                               rmt_container_material_owner_id: owner_id,
                                               location_id: to_location_id)
      return failed_response('Could not find or create bin asset location') unless bin_asset_location_id

      success_response('ok')
    end

    def validate_bin_asset_location_quantities(from_location_id, bin_sets = []) # rubocop:disable Metrics/AbcSize
      bin_sets.each do |set|
        qty = bin_asset_location_qty(set[:rmt_material_owner_party_role_id], set[:rmt_container_material_type_id], from_location_id)
        next if qty >= set[:quantity_bins].to_i

        owner_bin_type = find_owner_bin_type(set[:rmt_material_owner_party_role_id], set[:rmt_container_material_type_id])
        bin_type = owner_bin_type.container_material_type_code
        location_code = DB[:locations].where(id: from_location_id).get(:location_long_code)
        message = "Insufficient amount of #{bin_type} from #{owner_bin_type.owner_party_name} at #{location_code}: #{qty} Available"
        return validation_failed_response(OpenStruct.new(messages: { base: [message] }, instance: hash))
      end
      success_response('ok')
    end

    def bin_asset_location_qty(owner_id, type_id, location_id)
      DB[:bin_asset_locations].where(
        rmt_container_material_owner_id: DB[:rmt_container_material_owners].where(
          rmt_material_owner_party_role_id: owner_id,
          rmt_container_material_type_id: type_id
        ).get(:id),
        location_id: location_id
      ).get(:quantity) || AppConst::BIG_ZERO
    end

    def get_applicable_transaction_item_ids(loc_id)
      from_ids = DB[:bin_asset_transaction_items].where(bin_asset_from_location_id: loc_id).select_map(:id)
      to_ids = DB[:bin_asset_transaction_items].where(bin_asset_to_location_id: loc_id).select_map(:id)
      item_ids = (from_ids || []) + (to_ids || [])
      success_response('ok', item_ids.sort.uniq)
    end

    def for_select_rmt_deliveries
      DB[:rmt_deliveries].join(:farms, id: :farm_id)
                         .join(:orchards, id: Sequel[:rmt_deliveries][:orchard_id])
                         .select(:farm_code, :orchard_code, :date_delivered, Sequel[:rmt_deliveries][:id])
                         .map { |r| ["#{r[:farm_code]}_#{r[:orchard_code]}_#{r[:date_delivered].strftime('%d/%m/%Y')}", r[:id]] }.uniq
    end

    def resolve_for_header(header) # rubocop:disable Metrics/AbcSize
      values = {
        business_process_id: DB[:business_processes].where(id: header[:business_process_id]).get(:process),
        reference_number: header[:reference_number],
        asset_transaction_type_id: DB[:asset_transaction_types].where(id: header[:asset_transaction_type_id]).get(:transaction_type_code),
        bin_asset_to_location_id: DB[:locations].where(id: header[:bin_asset_to_location_id]).get(:location_long_code),
        total_quantity_bins: header[:quantity_bins]
      }
      values[:bin_asset_from_location_id] = DB[:locations].where(id: header[:bin_asset_from_location_id]).get(:location_long_code) unless header[:bin_asset_from_location_id].nil_or_empty?
      values[:fruit_reception_delivery_id] = rmt_delivery_code(header[:fruit_reception_delivery_id]) unless header[:fruit_reception_delivery_id].nil_or_empty?
      values[:truck_registration_number] = header[:truck_registration_number] unless header[:truck_registration_number].nil_or_empty?
      values
    end

    def rmt_delivery_code(del_id)
      DB[:rmt_deliveries].join(:farms, id: :farm_id)
                         .join(:orchards, id: Sequel[:rmt_deliveries][:orchard_id])
                         .where(Sequel[:rmt_deliveries][:id] => del_id)
                         .select(:farm_code, :orchard_code, :date_delivered, Sequel[:rmt_deliveries][:id])
                         .map { |r| "#{r[:farm_code]}_#{r[:orchard_code]}_#{r[:date_delivered].strftime('%d/%m/%Y')}" }
    end
  end
end
