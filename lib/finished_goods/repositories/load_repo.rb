# frozen_string_literal: true

module FinishedGoodsApp
  class LoadRepo < BaseRepo
    build_for_select :loads,
                     label: :order_number,
                     value: :id,
                     order_by: :order_number
    build_inactive_select :loads,
                          label: :order_number,
                          value: :id,
                          order_by: :order_number

    crud_calls_for :loads, name: :load, wrapper: Load

    def find_load_flat(id)
      find_with_association(:loads,
                            id,
                            parent_tables: [{ parent_table: :voyage_ports,
                                              columns: %i[port_id voyage_id],
                                              foreign_key: :pol_voyage_port_id,
                                              flatten_columns: { port_id: :pol_port_id, voyage_id: :voyage_id } },
                                            { parent_table: :voyage_ports,
                                              columns: %i[port_id],
                                              foreign_key: :pod_voyage_port_id,
                                              flatten_columns: { port_id: :pod_port_id } },
                                            { parent_table: :voyages,
                                              columns: %i[voyage_type_id vessel_id voyage_number year voyage_code],
                                              foreign_key: :voyage_id,
                                              flatten_columns: { voyage_type_id: :voyage_type_id,
                                                                 vessel_id: :vessel_id,
                                                                 voyage_number: :voyage_number,
                                                                 voyage_code: :voyage_code,
                                                                 year: :year } }],
                            sub_tables: [{ sub_table: :load_voyages,
                                           columns: %i[shipping_line_party_role_id
                                                       shipper_party_role_id
                                                       booking_reference
                                                       memo_pad],
                                           one_to_one: { shipping_line_party_role_id: :shipping_line_party_role_id,
                                                         shipper_party_role_id: :shipper_party_role_id,
                                                         booking_reference: :booking_reference,
                                                         memo_pad: :memo_pad } },
                                         { sub_table: :load_vehicles,
                                           columns: %i[vehicle_number],
                                           one_to_one: { vehicle_number: :vehicle_number } },
                                         { sub_table: :load_containers,
                                           columns: %i[container_code],
                                           one_to_one: { container_code: :container_code } }],
                            wrapper: LoadFlat)
    end

    def find_pallet_numbers_from(pallet_sequence_id: nil, load_id: nil)
      ds = DB[:pallets]
      ds = ds.where(id: DB[:pallet_sequences].where(id: pallet_sequence_id).select_map(:pallet_id)) unless pallet_sequence_id.nil?
      ds = ds.where(load_id: load_id) unless load_id.nil?
      ds.select_map(:pallet_number).flatten
    end

    def find_pallet_ids_from(pallet_sequence_id: nil, load_id: nil, pallet_numbers: nil)
      ds = DB[:pallets]
      ds = ds.where(id: B[:pallet_sequences].where(id: pallet_sequence_id).select_map(:pallet_id)) unless pallet_sequence_id.nil?
      ds = ds.where(load_id: load_id) unless load_id.nil?
      ds = ds.where(pallet_number: pallet_numbers) unless pallet_numbers.nil?
      ds.select_map(:id).flatten
    end

    def validate_pallets(pallet_numbers, allocated: nil, shipped: nil, has_nett_weight: false, has_gross_weight: false)
      ds = DB[:pallets].where(pallet_number: pallet_numbers)
      ds = ds.where(allocated: allocated) unless allocated.nil?
      ds = ds.where(shipped: shipped) unless shipped.nil?
      ds = ds.exclude { nett_weight.> 0 } if has_nett_weight # rubocop:disable Style/NumericPredicate
      ds = ds.exclude { gross_weight.> 0 } if has_gross_weight # rubocop:disable Style/NumericPredicate
      ds.select_map(:pallet_number)
    end

    def allocate_pallets(load_id, pallet_ids, user_name)
      DB[:pallets].where(id: pallet_ids).update(load_id: load_id, allocated: true, allocated_at: Time.now)
      log_multiple_statuses('pallets', pallet_ids, 'ALLOCATED', user_name: user_name)

      # updates load status allocated
      DB[:loads].where(id: load_id).update(allocated: true, allocated_at: Time.now)
      log_status('loads', load_id, 'ALLOCATED', user_name: user_name)

      ok_response
    end

    def unallocate_pallets(load_id, pallet_ids, user_name) # rubocop:disable Metrics/AbcSize
      DB[:pallets].where(id: pallet_ids).update(load_id: nil, allocated: false)
      log_multiple_statuses('pallets', pallet_ids, 'UNALLOCATED', user_name: user_name)

      # find unallocated loads
      allocated_loads = DB[:pallets].where(load_id: load_id).distinct.select_map(:load_id)
      unallocated_loads = [load_id] - allocated_loads

      # log status for loads where all pallets have been unallocated
      unless unallocated_loads.empty?
        DB[:loads].where(id: unallocated_loads).update(allocated: false)
        log_multiple_statuses('loads', unallocated_loads, 'UNALLOCATED', user_name: user_name)
      end

      ok_response
    end

    def ship_load(id)
      DB[:loads].where(id: id).update(shipped: true, shipped_at: Time.now)
    end

    def unship_load(id)
      DB[:loads].where(id: id).update(shipped: false, shipped_at: nil)
    end

    def ship_pallets(ids)
      DB[:pallets].where(id: ids).update(shipped: true, shipped_at: Time.now, exit_ref: 'SHIPPED')
    end

    def unship_pallets(ids)
      DB[:pallets].where(id: ids).update(shipped: false, shipped_at: nil, exit_ref: nil)
    end
  end
end
