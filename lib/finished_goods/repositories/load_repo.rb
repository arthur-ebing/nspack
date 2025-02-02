# frozen_string_literal: true

module FinishedGoodsApp
  class LoadRepo < BaseRepo
    crud_calls_for :loads, name: :load, exclude: [:delete]

    def delete_load(id)
      DB[:orders_loads].where(load_id: id).delete
      delete(:loads, id)
    end

    def for_select_loads(where: {}, exclude: {}, active: true)
      DB[:loads]
        .left_join(:orders_loads, load_id: :id)
        .where(Sequel[:loads][:active] => active)
        .where(convert_empty_values(where))
        .exclude(convert_empty_values(exclude))
        .distinct
        .select(Sequel[:loads][:id])
        .map { |r| [r[:id], r[:id]] }
    end

    def find_load(id) # rubocop:disable Metrics/AbcSize
      hash = find_with_association(
        :loads, id,
        parent_tables: [{ parent_table: :voyage_ports, foreign_key: :pod_voyage_port_id,
                          flatten_columns: { port_id: :pod_port_id,
                                             voyage_id: :voyage_id,
                                             eta: :eta,
                                             ata: :ata } },
                        { parent_table: :voyage_ports, foreign_key: :pol_voyage_port_id,
                          flatten_columns: { port_id: :pol_port_id, etd: :etd, atd: :atd } },
                        { parent_table: :depots, foreign_key: :depot_id,
                          flatten_columns: { depot_code: :depot_code } },
                        { parent_table: :voyages, foreign_key: :voyage_id,
                          flatten_columns: { voyage_type_id: :voyage_type_id,
                                             vessel_id: :vessel_id,
                                             voyage_number: :voyage_number,
                                             voyage_code: :voyage_code,
                                             year: :year } }],
        sub_tables: [{ sub_table: :load_voyages,
                       one_to_one: { shipping_line_party_role_id: :shipping_line_party_role_id,
                                     shipper_party_role_id: :shipper_party_role_id,
                                     booking_reference: :booking_reference,
                                     memo_pad: :memo_pad } },
                     { sub_table: :load_vehicles,
                       one_to_one: { vehicle_number: :vehicle_number } },
                     { sub_table: :load_containers,
                       one_to_one: { container_code: :container_code,
                                     cargo_temperature_id: :cargo_temperature_id,
                                     verified_gross_weight: :verified_gross_weight } }],

        lookup_functions: [{ function: :fn_current_status, args: ['loads', :id],  col_name: :status },
                           { function: :fn_party_role_name, args: [:customer_party_role_id], col_name: :customer },
                           { function: :fn_party_role_name, args: [:exporter_party_role_id], col_name: :exporter },
                           { function: :fn_party_role_name, args: [:billing_client_party_role_id], col_name: :billing_client },
                           { function: :fn_party_role_name, args: [:consignee_party_role_id], col_name: :consignee },
                           { function: :fn_party_role_name, args: [:final_receiver_party_role_id], col_name: :final_receiver }]
      )
      return nil if hash.nil?

      # Orders
      order_ids = select_values(:orders_loads, :order_id, load_id: id)
      hash[:order_id] = order_ids.one? ? order_ids.first : nil
      order_hash = find_hash(:orders, hash[:order_id]) || {}
      hash[:packed_tm_group_id] = order_hash[:packed_tm_group_id]
      hash[:marketing_org_party_role_id] = order_hash[:marketing_org_party_role_id]
      hash[:target_customer_party_role_id] = order_hash[:target_customer_party_role_id]

      # load_voyages
      hash[:load_voyage_id] = get_id(:load_voyages, load_id: id)
      hash[:shipping_line] = DB.get(Sequel.function(:fn_party_role_name, hash[:shipping_line_party_role_id]))
      hash[:shipper] = DB.get(Sequel.function(:fn_party_role_name, hash[:shipper_party_role_id]))

      # load_vehicles
      hash[:load_vehicle_id] = get_id(:load_vehicles, load_id: id)
      hash[:vehicle] = !hash[:load_vehicle_id].nil?

      # load_container
      hash[:load_container_id] = get_id(:load_containers, load_id: id)
      hash[:container] = !hash[:load_container_id].nil?
      hash[:temperature_code] = get(:cargo_temperatures, :temperature_code, hash[:cargo_temperature_id])

      # Voyage
      hash[:pol_port_code] = get(:ports, :port_code, hash[:pol_port_id])
      hash[:pod_port_code] = get(:ports, :port_code, hash[:pod_port_id])
      hash[:vessel_code] = get(:vessels, :vessel_code, hash[:vessel_id])

      # Load
      hash[:load_id] = id
      hash[:edi] = exists?(:edi_out_transactions, record_id: id)
      final_destination = MasterfilesApp::DestinationRepo.new.find_city(hash[:final_destination_id])
      hash[:destination_city] = final_destination.city_name
      hash[:destination_country] = final_destination.country_name
      hash[:iso_country_code] = final_destination.iso_country_code
      hash[:destination_region] = final_destination.region_name

      # Pallets
      pallets = DB[:pallets].where(load_id: id)
      hash[:temp_tail] = pallets.exclude(temp_tail: nil).get(:temp_tail)
      hash[:temp_tail_pallet_number] = pallets.exclude(temp_tail: nil).get(:pallet_number)
      hash[:pallet_count] = pallets.select_map(:pallet_number).count
      hash[:nett_weight] = pallets.select_map(:nett_weight).map!(&:to_i).sum

      # Addendum
      hash[:addendum] = exists?(:titan_requests, load_id: id)

      Load.new(hash)
    end

    def set_pallets_target_customer(target_customer_id, pallet_ids)
      pallet_sequence_ids = select_values(:pallet_sequences, :id, pallet_id: pallet_ids)
      existing_pallet_sequence_ids = select_values(:pallet_sequences, :id, target_customer_party_role_id: target_customer_id)
      removed_pallet_sequence_ids = existing_pallet_sequence_ids - pallet_sequence_ids
      new_pallet_sequence_ids = pallet_sequence_ids - existing_pallet_sequence_ids
      DB[:pallet_sequences].where(id: removed_pallet_sequence_ids).update(target_customer_party_role_id: nil)
      DB[:pallet_sequences].where(id: new_pallet_sequence_ids).update(target_customer_party_role_id: target_customer_id)
    end

    def allocate_pallets(load_id, pallet_numbers, user)
      return if pallet_numbers.nil_or_empty?

      pallet_ids = select_values(:pallets, :id, pallet_number: pallet_numbers)
      update(:pallets, pallet_ids, load_id: load_id, allocated: true, allocated_at: Time.now)
      log_multiple_statuses(:pallets, pallet_ids, 'ALLOCATED', user_name: user.user_name)

      allocated_count = select_values(:pallets, :id, load_id: load_id).length
      max_count = get(:loads, :rmt_load, load_id) ? AppConst::CR_FG.max_bin_count_for_load? : AppConst::CR_FG.max_pallet_count_for_load?
      raise Crossbeams::InfoError, "Allocation exceeded max count of #{max_count} pallets on load" if allocated_count > max_count

      # updates load status allocated
      update(:loads, load_id, allocated: true, allocated_at: Time.now)
      log_status(:loads, load_id, 'ALLOCATED', user_name: user.user_name)
    end

    def unallocate_pallets(pallet_numbers, user)
      return if pallet_numbers.nil_or_empty?

      pallet_ids = select_values(:pallets, :id, pallet_number: pallet_numbers)
      load_ids = select_values(:pallets, :load_id, id: pallet_ids).uniq
      update(:pallets, pallet_ids, load_id: nil, allocated: false, temp_tail: nil)
      log_multiple_statuses(:pallets, pallet_ids, 'UNALLOCATED', user_name: user.user_name)

      DB[:pallet_sequences].where(pallet_id: pallet_ids).update(order_item_id: nil)

      # log status for loads where all pallets have been unallocated
      load_ids.each do |load_id|
        next if exists?(:pallets, load_id: load_id)

        update(:loads, load_id, allocated: false)
        log_status(:loads, load_id, 'UNALLOCATED', user_name: user.user_name)
      end
    end

    def local_non_stock_pallets
      tm_id = MasterfilesApp::TargetMarketRepo.new.find_tm_group_id_from_code('LO', AppConst::PACKED_TM_GROUP)
      DB[:pallet_sequences]
        .join(:pallets, id: :pallet_id)
        .where(in_stock: false, packed_tm_group_id: tm_id, shipped: false)
        .distinct
        .select_map(:pallet_id)
    end

    def list_pallets_for_load(id) # rubocop:disable Metrics/AbcSize
      load = find_load(id)
      params = {
        packed_tm_group_id: load.packed_tm_group_id,
        marketing_org_party_role_id: load.marketing_org_party_role_id,
        target_customer_party_role_id: load.target_customer_party_role_id,
        rmt_grade: load.rmt_load
      }

      pallet_ids = DB[:pallet_sequences]
                   .join(:cultivar_groups, id: :cultivar_group_id)
                   .join(:commodities, id: Sequel[:cultivar_groups][:commodity_id])
                   .left_join(:cultivars, id: Sequel[:pallet_sequences][:cultivar_id])
                   .left_join(:grades, id: Sequel[:pallet_sequences][:grade_id])
                   .where(params.compact)
                   .select_map(:pallet_id)

      # Get all allocated pallets too - in case they no longer match the above filter criteria:
      allocated_ids = DB[:pallets].where(load_id: id).select_map(:id)
      pallet_ids = (pallet_ids + allocated_ids).uniq

      DB[:pallets]
        .where(in_stock: true, id: pallet_ids)
        .where(Sequel.lit("load_id is null OR load_id = #{id}"))
        .distinct.select_map(:id) + [0]
    end

    def load_is_on_order?(id)
      exists?(:orders_loads, load_id: id)
    end

    def link_order_to_load(order_id, load_id)
      return if order_id.nil? || load_id.nil?

      create(:orders_loads, load_id: load_id, order_id: order_id)
      DB[:orders].where(id: order_id, shipped: true).update(shipped: false)
    end
  end
end
