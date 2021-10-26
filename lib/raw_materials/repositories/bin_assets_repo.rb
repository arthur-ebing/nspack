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
      loc_type_ids = DB[:location_types].where(location_type_code: [AppConst::LOCATION_TYPES_BIN_ASSET, AppConst::LOCATION_TYPES_FARM]).select_map(:id)
      location_repo.for_select_locations(where: { location_type_id: loc_type_ids })
    end

    def for_select_onsite_bin_asset_locations
      location_type_id = DB[:location_types].where(location_type_code: AppConst::LOCATION_TYPES_BIN_ASSET).get(:id)
      location_repo.for_select_locations(where: { location_type_id: location_type_id })
    end

    def for_select_farm_bin_asset_locations
      location_type_id = DB[:location_types].where(location_type_code: AppConst::LOCATION_TYPES_FARM).get(:id)
      location_repo.for_select_locations(where: { location_type_id: location_type_id })
    end

    def for_select_available_bin_asset_locations
      available_ids = DB[:bin_asset_locations].select_map(:location_id)
      loc_type_ids = DB[:location_types].where(location_type_code: [AppConst::LOCATION_TYPES_BIN_ASSET, AppConst::LOCATION_TYPES_FARM]).select_map(:id)
      location_repo.for_select_locations(where: { location_type_id: loc_type_ids, id: available_ids })
    end

    def for_select_available_farm_bin_asset_locations
      available_ids = DB[:bin_asset_locations].select_map(:location_id)
      location_type_id = DB[:location_types].where(location_type_code: AppConst::LOCATION_TYPES_FARM).get(:id)
      location_repo.for_select_locations(where: { location_type_id: location_type_id, id: available_ids })
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
      location_ds = DB[:bin_asset_locations].where(rmt_container_material_owner_id: owner_id,
                                                   location_id: location_id)
      return failed_response('Bin Asset location does not exist') unless location_ds.first

      existing_qty = location_ds.get(:quantity) || 0
      qty = add ? (existing_qty + quantity) : (existing_qty - quantity)
      if qty.negative?
        failed_response('can not update with negative amount', qty)
      else
        location_ds.update(quantity: qty)
        success_response('updated successfully')
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

    def bin_asset_transactions_queue_ids
      DB[:bin_asset_transactions_queue]
        .select_map(:id)
    end

    def unresolved_bin_asset_move_error_log_ids
      DB[:bin_asset_move_error_logs]
        .where(completed: false)
        .select_map(:id)
    end

    def bin_asset_transactions_queue_records_for(queue_ids)
      return [] if queue_ids.nil_or_empty?

      query = <<~SQL
        SELECT bin_event_type, pallet, changes_made,
               array(SELECT DISTINCT rmt_bin_id
                     FROM bin_asset_transactions_queue a
                     WHERE a.bin_event_type = bin_asset_transactions_queue.bin_event_type
                     AND id IN ?) AS rmt_bin_ids
        FROM bin_asset_transactions_queue
        WHERE id IN ?
        GROUP BY bin_event_type, pallet, changes_made
      SQL
      DB[query, queue_ids, queue_ids].all
    end

    def delete_transactions_queue_records(queue_ids)
      DB[:bin_asset_transactions_queue]
        .where(id: queue_ids)
        .delete
    end

    def transactions_missing_owner_attributes(bin_event_type, is_pallet, rec_ids)
      return [] if rec_ids.nil_or_empty?

      query = if %w[BIN_DELETED REBIN_DELETED].include? bin_event_type
                missing_owner_attributes_query_for_deleted_bins
              else
                is_pallet ? missing_owner_attributes_query_for_pallets : missing_owner_attributes_query_for_rmt_bins
              end
      DB[query, rec_ids].all.map { |r| r[:id] }
    end

    def missing_owner_attributes_query_for_deleted_bins
      <<~SQL
        SELECT a.row_data_id AS id FROM audit.logged_actions a
        WHERE a.table_name = 'rmt_bins'
        AND a.action = 'D'
        AND a.row_data_id IN ?
        AND (a.row_data ->'rmt_material_owner_party_role_id' IS NULL OR a.row_data ->'rmt_container_material_type_id' IS NULL)
        ORDER BY id
      SQL
    end

    def missing_owner_attributes_query_for_pallets
      <<~SQL
        SELECT pallets.id FROM pallets
        JOIN pallet_sequences ON pallet_sequences.pallet_id = pallets.id
        JOIN rmt_bins ON pallet_sequences.source_bin_id = rmt_bins.id
        WHERE pallets.id IN ?
        AND (rmt_bins.rmt_material_owner_party_role_id IS NULL OR rmt_bins.rmt_container_material_type_id IS NULL)
        ORDER BY pallets.id
      SQL
    end

    def missing_owner_attributes_query_for_rmt_bins
      <<~SQL
        SELECT id FROM rmt_bins
        WHERE id IN ?
        AND (rmt_material_owner_party_role_id IS NULL OR rmt_container_material_type_id IS NULL)
        ORDER BY id
      SQL
    end

    def bin_asset_move_error_logs_for(error_log_ids)
      return [] if error_log_ids.nil_or_empty?

      query = <<~SQL
        SELECT bin_asset_location_id, sum(quantity) as quantity
        FROM bin_asset_move_error_logs
        WHERE id IN ?
        GROUP BY bin_asset_location_id
      SQL
      DB[query, error_log_ids].all
    end

    def update_quantity_for_bin_asset_location(bin_asset_location_id, quantity)
      existing_qty = get(:bin_asset_locations, bin_asset_location_id, :quantity) || 0
      qty = existing_qty - quantity

      if qty.negative?
        failed_response('can not update with negative amount', qty)
      else
        update(:bin_asset_locations, bin_asset_location_id, quantity: qty)
        success_response('updated successfully')
      end
    end

    def update_error_logs_for_bin_asset_location(bin_asset_location_id, attrs)
      DB[:bin_asset_move_error_logs]
        .where(bin_asset_location_id: bin_asset_location_id)
        .update(attrs)
    end

    def bin_event_type_delivery_sets(bin_event_type, rec_ids)
      return {} if rec_ids.nil_or_empty?

      query = case bin_event_type
              when 'BIN_DISPATCHED_VIA_FG', 'BIN_UNSHIPPED_VIA_FG', 'BIN_PALLET_MATERIAL_OWNER_CHANGED'
                delivery_sets_query_for_pallet_bins
              when 'BIN_DISPATCHED_VIA_RMT', 'BIN_UNSHIPPED'
                delivery_sets_query_for_allocated_bins
              when 'BIN_DELETED', 'REBIN_DELETED'
                delivery_sets_query_for_deleted_bins
              else
                # 'DELIVERY_RECEIVED', 'REBIN_CREATED', 'BIN_TIPPED'
                # 'BIN_UNTIPPED', 'FARM_CHANGED', 'MATERIAL_OWNER_CHANGED', 'BIN_SCRAPPED'
                # 'BIN_UNSCRAPPED' ,'REBIN_MATERIAL_OWNER_CHANGED', 'REBIN_SCRAPPED', 'REBIN_UNSCRAPPED'
                delivery_sets_query_for_rmt_bins
              end
      DB[query, rec_ids].all
    end

    def delivery_sets_query_for_pallet_bins
      <<~SQL
        SELECT COALESCE(rmt_delivery_id, scrapped_rmt_delivery_id) AS rmt_delivery_id, production_run_rebin_id,
               COALESCE(rcmo.rmt_material_owner_party_role_id, rmt_bins.rmt_material_owner_party_role_id) AS rmt_material_owner_party_role_id,
               COALESCE(rcmo.rmt_container_material_type_id, rmt_bins.rmt_container_material_type_id) AS rmt_container_material_type_id,
               pallets.rmt_container_material_owner_id, loads.depot_id AS dest_depot_id,
               SUM(qty_bins) AS quantity_bins
        FROM pallets
        JOIN pallet_sequences ON pallet_sequences.pallet_id = pallets.id
        JOIN rmt_bins ON pallet_sequences.source_bin_id = rmt_bins.id
        LEFT JOIN loads ON loads.id = pallets.load_id
        LEFT JOIN rmt_container_material_owners rcmo ON rcmo.id = pallets.rmt_container_material_owner_id
        WHERE pallets.id IN ?
        GROUP BY 1, production_run_rebin_id, 3, 4, pallets.rmt_container_material_owner_id, loads.depot_id
      SQL
    end

    def delivery_sets_query_for_allocated_bins
      <<~SQL
        SELECT COALESCE(rmt_delivery_id, scrapped_rmt_delivery_id) AS rmt_delivery_id, production_run_rebin_id,
               rmt_bins.rmt_material_owner_party_role_id, rmt_bins.rmt_container_material_type_id, bin_loads.dest_depot_id,
               SUM(rmt_bins.qty_bins) AS quantity_bins
        FROM rmt_bins
        JOIN bin_load_products ON bin_load_products.id = rmt_bins.bin_load_product_id
        JOIN bin_loads ON bin_loads.id = bin_load_products.bin_load_id
        WHERE rmt_bins.id IN ?
        GROUP BY 1, production_run_rebin_id, rmt_bins.rmt_material_owner_party_role_id, rmt_bins.rmt_container_material_type_id, bin_loads.dest_depot_id
      SQL
    end

    def delivery_sets_query_for_deleted_bins
      <<~SQL
        SELECT COALESCE(a.row_data ->'rmt_delivery_id', a.row_data ->'scrapped_rmt_delivery_id') AS rmt_delivery_id,
               a.row_data ->'production_run_rebin_id' AS production_run_rebin_id,
               a.row_data ->'rmt_material_owner_party_role_id' AS rmt_material_owner_party_role_id,
               a.row_data ->'rmt_container_material_type_id' AS rmt_container_material_type_id,
               SUM((a.row_data ->'qty_bins')::INTEGER) AS quantity_bins
        FROM audit.logged_actions a
        WHERE a.table_name = 'rmt_bins'
        AND a.action = 'D'
        AND a.row_data_id IN ?
        GROUP BY rmt_delivery_id, production_run_rebin_id, rmt_material_owner_party_role_id, rmt_container_material_type_id
      SQL
    end

    def delivery_sets_query_for_rmt_bins
      <<~SQL
        SELECT COALESCE(rmt_delivery_id, scrapped_rmt_delivery_id) AS rmt_delivery_id, production_run_rebin_id,
               rmt_material_owner_party_role_id, rmt_container_material_type_id,
               SUM(qty_bins) AS quantity_bins
        FROM rmt_bins
        WHERE rmt_bins.id IN ?
        GROUP BY 1, production_run_rebin_id, rmt_material_owner_party_role_id, rmt_container_material_type_id
      SQL
    end

    def find_rmt_delivery_attrs(rmt_delivery_id)
      DB[:rmt_deliveries]
        .where(id: rmt_delivery_id)
        .select(:farm_id,
                :truck_registration_number,
                :reference_number)
        .first
    end

    def create_bin_asset_move_error_log(attrs)
      bin_asset_location_id = get_id(:bin_asset_locations, attrs.slice(:rmt_container_material_owner_id, :location_id))

      create(:bin_asset_move_error_logs,
             { bin_asset_location_id: bin_asset_location_id,
               quantity: attrs[:quantity],
               error_message: 'Insufficient stock' })
    end

    def get_dest_depot_location_id(dest_depot_id)
      DB[:locations]
        .where(location_long_code: DB[:depots]
                                   .where(id: dest_depot_id)
                                   .get(:depot_code))
        .get(:id)
    end
  end
end
