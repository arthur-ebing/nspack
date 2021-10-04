# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

module MasterfilesApp
  class LocationRepo < BaseRepo
    build_for_select :locations,
                     label: :location_long_code,
                     value: :id,
                     order_by: :location_long_code
    build_inactive_select :locations,
                          label: :location_long_code,
                          value: :id,
                          order_by: :location_long_code

    build_for_select :location_assignments,
                     label: :assignment_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :assignment_code

    build_for_select :location_storage_types,
                     label: :storage_type_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :storage_type_code

    build_for_select :location_types,
                     label: :location_type_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :location_type_code

    build_for_select :location_storage_definitions,
                     label: :storage_definition_code,
                     value: :id,
                     order_by: :storage_definition_code

    crud_calls_for :locations, name: :location
    crud_calls_for :location_assignments, name: :location_assignment, wrapper: LocationAssignment
    crud_calls_for :location_storage_types, name: :location_storage_type, wrapper: LocationStorageType
    crud_calls_for :location_types, name: :location_type, wrapper: LocationType
    crud_calls_for :location_storage_definitions, name: :location_storage_definition, wrapper: LocationStorageDefinition

    def for_select_receiving_bays
      location_type_id = DB[:location_types].where(location_type_code: AppConst::LOCATION_TYPES_RECEIVING_BAY).get(:id)
      for_select_locations(where: { location_type_id: location_type_id, can_store_stock: true })
    end

    def find_location_by(key, val) # rubocop:disable Metrics/AbcSize
      hash = DB[:locations]
             .join(:location_storage_types, id: :primary_storage_type_id)
             .join(:location_types, id: Sequel[:locations][:location_type_id])
             .join(:location_assignments, id: Sequel[:locations][:primary_assignment_id])
             .select(Sequel[:locations].*,
                     Sequel[:location_storage_types][:storage_type_code],
                     Sequel[:location_types][:location_type_code],
                     Sequel[:location_assignments][:assignment_code])
             .where(Sequel[:locations][key] => val).first
      return nil if hash.nil?

      Location.new(hash)
    end

    def find_locations_by_location_type_and_storage_type(location_type_code, storage_type_code)
      DB[:locations]
        .join(:location_types, id: :location_type_id)
        .join(:location_storage_types_locations, location_id: Sequel[:locations][:id])
        .join(:location_storage_types, id: Sequel[:location_storage_types_locations][:location_storage_type_id])
        .select(Sequel[:locations][:id], :location_short_code)
        .where(location_type_code: location_type_code)
        .where(storage_type_code: storage_type_code)
        .map(%i[location_short_code id])
    end

    def find_location(id)
      find_location_by(:id, id)
    end

    def get_parent_location(id)
      query = <<~SQL
        select d.id
        from locations p
        join tree_locations t on t.descendant_location_id=p.id
        join locations d on d.id=t.ancestor_location_id
        where p.id=?
        AND t.path_length = 1
      SQL
      DB[query, id].select_map(:id).first
    end

    def find_max_position_for_deck_location(id)
      query = <<~SQL
        SELECT COUNT(p.*) as num_positions
        FROM locations d
        JOIN tree_locations t on t.ancestor_location_id=d.id
        join locations p on p.id=t.descendant_location_id
        where d.id = ?
        AND t.path_length = 1
      SQL
      DB[query, id].select_map(:num_positions).first
    end

    def find_filled_deck_positions(location_to_id)
      query = <<~SQL
        select cast(substring(p.location_long_code from '\\d+$') as int) as pos
        from locations d
        join tree_locations t on t.ancestor_location_id=d.id
        join locations p on p.id=t.descendant_location_id
        join pallets s on s.location_id=p.id
        where d.id = ?
        AND t.path_length = 1
      SQL
      DB[query, location_to_id].select_map(:pos)
    end

    def get_deck_pallets(id)
      query = <<~SQL
        select cast(substring(p.location_long_code from '\\d+$') as int) as pos, s.pallet_number, s.id as pallet_id
        from locations d
        join tree_locations t on t.ancestor_location_id=d.id
        join locations p on p.id=t.descendant_location_id
        left outer join pallets s on s.location_id=p.id
        where d.id = ?
        AND t.path_length = 1
        order by pos desc
      SQL
      DB[query, id].all
    end

    def find_location_by_location_long_code(code)
      find_location_by(:location_long_code, code)
    end

    def location_exists(location_long_code, location_short_code)
      return failed_response(%(Location "#{location_long_code}" already exists)) if exists?(:locations, location_long_code: location_long_code)
      return failed_response(%(Location with short code "#{location_short_code}" already exists)) if !location_short_code.nil? && exists?(:locations, location_short_code: location_short_code)

      ok_response
    end

    def location_id_from_long_code(location_long_code)
      get_id(:locations, location_long_code: location_long_code)
    end

    def location_id_from_short_code(location_short_code)
      get_id(:locations, location_short_code: location_short_code)
    end

    # Given a scanned or entered value and the scan_field
    # value from a form, return the valid location_id or nil.
    #
    # @param value [string,integer] the scanned or entered value
    # @param scan_field [string] the type of scan (blank if the value was typed in)
    # @return [intger,nil] the location_id or nil if input was invalid or not found
    def resolve_location_id_from_scan(value, scan_field)
      not_found = nil
      if ['', 'location_short_code'].include?(scan_field)
        location_id_from_short_code(value)
      elsif value.is_a?(Numeric) || value =~ /\A\d+\Z/
        get_id(:locations, id: value)
      else
        not_found
      end
    end

    def create_root_location(params)
      id = create_location(params)
      DB[:location_storage_types_locations].insert(location_id: id,
                                                   location_storage_type_id: params[:primary_storage_type_id])
      DB[:location_assignments_locations].insert(location_id: id,
                                                 location_assignment_id: params[:primary_assignment_id])
      DB[:tree_locations].insert(ancestor_location_id: id,
                                 descendant_location_id: id,
                                 path_length: 0)
      id
    end

    def create_child_location(parent_id, res)
      id = create_location(res)
      DB[:location_storage_types_locations].insert(location_id: id,
                                                   location_storage_type_id: res[:primary_storage_type_id])
      DB[:location_assignments_locations].insert(location_id: id,
                                                 location_assignment_id: res[:primary_assignment_id])
      DB.execute(<<~SQL)
        INSERT INTO tree_locations (ancestor_location_id, descendant_location_id, path_length)
        SELECT t.ancestor_location_id, #{id}, t.path_length + 1
        FROM tree_locations AS t
        WHERE t.descendant_location_id = #{parent_id}
        UNION ALL
        SELECT #{id}, #{id}, 0;
      SQL
      id
    end

    def create_location(attrs)
      receiving_bay = location_type_is_receiving_bay(attrs[:location_type_id])
      failed_message = 'Location must store stock if its location type is receiving bay'
      raise Crossbeams::FrameworkError, failed_message if receiving_bay && !attrs[:can_store_stock]

      create(:locations, attrs)
    end

    def update_location(id, attrs)
      receiving_bay = location_type_is_receiving_bay(attrs[:location_type_id])
      failed_message = 'Location must store stock if its location type is receiving bay'
      raise Crossbeams::FrameworkError, failed_message if receiving_bay && !attrs[:can_store_stock]

      update(:locations, id, attrs)
    end

    def location_type_is_receiving_bay(location_type_id)
      code = DB[:location_types].where(id: location_type_id).get(:location_type_code)
      code == AppConst::LOCATION_TYPES_RECEIVING_BAY
    end

    def location_has_children(id)
      DB.select(1).where(DB[:tree_locations].where(ancestor_location_id: id).exclude(descendant_location_id: id).exists).one?
    end

    def delete_location(id)
      DB[:tree_locations].where(ancestor_location_id: id).or(descendant_location_id: id).delete
      DB[:location_storage_types_locations].where(location_id: id).delete
      DB[:location_assignments_locations].where(location_id: id).delete
      DB[:locations].where(id: id).delete
    end

    def for_select_location_storage_types_for(id)
      dataset = DB[:location_storage_types_locations].join(:location_storage_types, id: :location_storage_type_id).where(Sequel[:location_storage_types_locations][:location_id] => id)
      select_two(dataset, :storage_type_code, :id, nil)
    end

    def location_storage_types(id)
      DB[:location_storage_types_locations]
        .join(:location_storage_types, id: :location_storage_type_id)
        .where(Sequel[:location_storage_types_locations][:location_id] => id)
        .select_map(:storage_type_code)
    end

    def for_select_location_assignments_for(id)
      dataset = DB[:location_assignments_locations].join(:location_assignments, id: :location_assignment_id).where(Sequel[:location_assignments_locations][:location_id] => id)
      select_two(dataset, :assignment_code, :id, nil)
    end

    def get_locations_type_code(id)
      query = <<~SQL
        select t.location_type_code
        from locations l
        join location_types t on t.id=l.location_type_id
        join location_storage_types s on s.id=l.primary_storage_type_id
        where l.id = ?
      SQL
      DB[query, id].first[:location_type_code]
    end

    def find_warehouse_pallets_locations
      query = <<~SQL
        select l.id, l.location_long_code
        from locations l
        join location_types t on t.id=l.location_type_id
        join location_storage_types s on s.id=l.primary_storage_type_id
        where s.storage_type_code = ? and t.location_type_code = ?
      SQL
      DB[query, AppConst::STORAGE_TYPE_PALLETS, AppConst::LOCATION_TYPES_WAREHOUSE].all.map { |r| [r[:location_long_code], r[:id]] }
    end

    def link_assignments(id, multiselect_ids)
      return failed_response('Choose at least one assignment') if multiselect_ids.empty?

      location = find_location(id)
      return failed_response('The primary assignment must be included in your selection') unless multiselect_ids.include?(location.primary_assignment_id)

      del = "DELETE FROM location_assignments_locations WHERE location_id = #{id}"
      ins = []
      multiselect_ids.each do |m_id|
        ins << "INSERT INTO location_assignments_locations (location_id, location_assignment_id) VALUES(#{id}, #{m_id});"
      end
      DB.execute(del)
      DB.execute(ins.join("\n"))
      ok_response
    end

    def link_storage_types(id, multiselect_ids)
      return failed_response('Choose at least one storage type') if multiselect_ids.empty?

      location = find_location(id)
      return failed_response('The primary storage type must be included in your selection') unless multiselect_ids.include?(location.primary_storage_type_id)

      del = "DELETE FROM location_storage_types_locations WHERE location_id = #{id}"
      ins = []
      multiselect_ids.each do |m_id|
        ins << "INSERT INTO location_storage_types_locations (location_id, location_storage_type_id) VALUES(#{id}, #{m_id});"
      end
      DB.execute(del)
      DB.execute(ins.join("\n"))
      ok_response
    end

    def location_long_code_suggestion(ancestor_id, location_type_id)
      sibling_count = DB[:tree_locations].where(path_length: 1).where(ancestor_location_id: ancestor_id).count
      code = ''
      code += "#{find_hash(:locations, ancestor_id)[:location_long_code]}_" unless location_is_root?(ancestor_id)
      code += type_abbreviation(location_type_id) + (sibling_count + 1).to_s
      success_response('ok', code)
    end

    def type_abbreviation(location_type_id)
      find_hash(:location_types, location_type_id)[:short_code]
    end

    def location_is_root?(id)
      DB[:tree_locations].where(descendant_location_id: id).count == 1
    end

    def can_be_moved_location_type_ids
      DB[:location_types].where(can_be_moved: true).select_map(:id)
    end

    def location_type_id_from(location_type_code)
      DB[:location_types].where(location_type_code: location_type_code).get(:id)
    end

    def descendants_for_ancestor_id(ancestor_id)
      DB[:tree_locations].where(ancestor_location_id: ancestor_id).select_map(:descendant_location_id)
    end

    def check_location_storage_types(values)
      qry = sql_for_missing_str_values(values, 'location_storage_types', 'storage_type_code')
      res = DB[qry].select_map
      if res.empty?
        ok_response
      else
        failed_response(res.map { |r| "#{r} is not a valid storage type" }.join(', '))
      end
    end

    def check_location_assignments(values)
      qry = sql_for_missing_str_values(values, 'location_assignments', 'assignment_code')
      res = DB[qry].select_map
      if res.empty?
        ok_response
      else
        failed_response(res.map { |r| "#{r} is not a valid assignment" }.join(', '))
      end
    end

    def check_location_types(values)
      qry = sql_for_missing_str_values(values, 'location_types', 'location_type_code')
      res = DB[qry].select_map
      if res.empty?
        ok_response
      else
        failed_response(res.map { |r| "#{r} is not a valid location type" }.join(', '))
      end
    end

    def check_storage_definitions(values)
      qry = sql_for_missing_str_values(values, 'location_storage_definitions', 'storage_definition_code')
      res = DB[qry].select_map
      if res.empty?
        ok_response
      else
        failed_response(res.map { |r| "#{r} is not a valid storage definition" }.join(', '))
      end
    end

    def check_locations(values)
      qry = sql_for_missing_str_values(values, 'locations', 'location_long_code')
      res = DB[qry].select_map
      if res.empty?
        ok_response
      else
        failed_response(res.map { |r| "#{r} is not a valid location" }.join(', '))
      end
    end

    def suggested_short_code(storage_type, id_lookup: true)
      storage_type = if id_lookup
                       DB[:location_storage_types].where(id: storage_type)
                     else
                       DB[:location_storage_types].where(storage_type_code: storage_type)
                     end
      return failed_response('storage type does not exist') unless storage_type.first

      prefix = storage_type.get(:location_short_code_prefix)
      return failed_response('no prefix') unless prefix

      query = <<~SQL
        SELECT max(locations.location_short_code)
        FROM locations
        WHERE locations.location_short_code LIKE '#{prefix}%';
      SQL

      last_val = DB[query].single_value
      code = last_val ? last_val.succ : (prefix + '_AAA')

      success_response('ok', code)
    end

    def find_location_stock(location_id, type)
      query = if type == 'pallets'
                location_stock_query_for_pallets
              else
                location_stock_query_for_bins
              end
      DB[query, location_id].all
    end

    def for_select_location_for_assignment(assignment_code)
      DB[:locations]
        .join(:location_assignments, id: :primary_assignment_id)
        .where(assignment_code: assignment_code)
        .select(Sequel[:locations][:id], :location_short_code)
        .map(%i[location_short_code id])
    end

    def location_pallets_count(location_id)
      DB[:pallets].where(location_id: location_id).count
    end

    def belongs_to_parent?(child_location_id, parent_location_id)
      !DB[:tree_locations]
        .where(ancestor_location_id: parent_location_id, descendant_location_id: child_location_id)
        .first.nil?
    end

    private

    def sql_for_missing_str_values(values, table, column)
      <<~SQL
        WITH v (code) AS (
         VALUES ('#{values.join("'), ('")}')
        )
        SELECT v.code
        FROM v
          LEFT JOIN #{table} i ON i.#{column} = v.code
        WHERE i.id is null;
      SQL
    end

    def location_stock_query_for_pallets
      <<~SQL
         SELECT DISTINCT ON (pallet_id) id, pallet_id, pallet_number, pallet_sequence_number, location,
          carton_quantity, pallet_carton_quantity, pallet_size, pallet_age, stock_age, cold_age, ambient_age,
          pack_to_inspect_age, inspect_to_cold_age, inspect_to_exit_warm_age, created_at, first_cold_storage_at,
          stock_created_at, palletized_at, govt_first_inspection_at, shipped_at, govt_reinspection_at, allocated_at,
          verified_at, allocated, shipped, in_stock, inspected, inspection_date, palletized, production_run_id,
          farm, farm_group, puc, orchard, commodity, cultivar, marketing_variety, grade, std_size,
          actual_count, size_ref, std_pack, std_ctns, packed_tm_group, mark, inventory_code, fruit_sticker,
          fruit_sticker_2, marketing_org, pallet_base, stack_type, gross_weight, nett_weight, sequence_nett_weight,
          basic_pack, packhouse, line, pick_ref, phc, sell_by_code, product_chars, verification_result,
          scrapped_at, scrapped, partially_palletized, reinspected, verified, verification_passed, status,
          build_status, load_id, vessel, voyage, container, internal_container, temp_code, vehicle_number,
          cooled, pol, pod, final_destination, inspected_dest_country, customer, consignee, final_receiver,
          exporter, country, region, arrival_date, departure_date, pallet_verification_failed,
          verification_failure_reason, scanned_carton, cpp, bom, client_size_ref, treatments, order_number,
          pm_type, pm_subtype, cultivar_group, season, customer_variety, plt_packhouse, plt_line, exit_ref,
          seq_exit_ref, gross_weight_measured_at, partially_palletized_at, govt_inspection_passed, inspection_age,
          intake_created_at, active, temp_tail, extended_columns, seq_scrapped_at, depot_pallet, edi_in_file,
          edi_in_consignment_note_number, govt_inspection_sheet_id, addendum_manifest, packed_at, packed_date,
          packed_week, repacked, repacked_at, repacked_date, repacked_from_pallet_id, failed_otmc_results,
          failed_otmc, CASE WHEN fn_pallet_verification_failed(pallet_id) THEN 'error' ELSE colour_rule END AS colour_rule
        FROM vw_pallet_sequence_flat
        JOIN tree_locations ON tree_locations.descendant_location_id = vw_pallet_sequence_flat.location_id
        WHERE NOT shipped AND NOT scrapped AND tree_locations.ancestor_location_id = ?
        ORDER BY pallet_id, pallet_number DESC
      SQL
    end

    def location_stock_query_for_bins
      <<~SQL
        SELECT DISTINCT ON (id) id, rmt_delivery_id, season_id, discrete_bin, cultivar_id, orchard_id, farm_id, rmt_class_id,
          rmt_container_type_id, rmt_container_material_type_id, cultivar_group_id, puc_id, exit_ref, qty_bins,
          bin_asset_number, tipped_asset_number, rmt_inner_container_type_id, rmt_inner_container_material_id,
          qty_inner_bins, production_run_rebin_id, production_run_tipped_id, bin_tipping_plant_resource_id,
          bin_fullness, nett_weight, gross_weight, active, bin_tipped, created_at, updated_at, date_picked,
          bin_received_date, bin_received_date_time, bin_tipped_date, bin_tipped_date_time, exit_ref_date,
          exit_ref_date_time, rebin_created_at, scrapped, scrapped_at, cultivar_group_code, cultivar_name,
          cultivar_description, farm_group_code, farm_code, orchard_code, puc_code, rmt_class_code,
          location_long_code, container_material_type_code, container_type_code, rmt_delivery_truck_registration_number,
          season_code, colour_rule, status
        FROM vw_bins
        JOIN tree_locations ON tree_locations.descendant_location_id = vw_bins.location_id
        WHERE NOT scrapped AND null_exit_ref AND tree_locations.ancestor_location_id = ?
        ORDER BY id DESC
      SQL
    end
  end
end
# rubocop:enable Metrics/ClassLength
