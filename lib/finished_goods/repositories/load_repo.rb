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
      hash = find_with_association(:loads,
                                   id,
                                   parent_tables: [{ parent_table: :voyage_ports,
                                                     columns: %i[port_id voyage_id],
                                                     foreign_key: :pol_voyage_port_id,
                                                     flatten_columns: { port_id: :pol_port_id,
                                                                        voyage_id: :voyage_id } },
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
                                                              memo_pad]  }])
      return LoadFlat.new(hash) if hash.nil?

      flatten_columns = { shipping_line_party_role_id: :shipping_line_party_role_id,
                          shipper_party_role_id: :shipper_party_role_id,
                          booking_reference: :booking_reference,
                          memo_pad: :memo_pad }
      sub_hash = hash.delete(:load_voyages).first
      sub_hash ||= {}
      flatten_columns.each { |col, new_name|  hash[new_name] = sub_hash.delete(col) }

      LoadFlat.new(hash)
    end

    def add_pallets(load_id, pallet_ids, user_name)
      # checks for unallocated and un-shipped pallets
      ds = DB[:pallets].where(id: pallet_ids, allocated: false, shipped: false)
      pallet_ids = ds.select_map(:id)

      # allocates pallets
      ds.update(load_id: load_id, allocated: true, allocated_at: Time.now)
      log_multiple_statuses('pallets', pallet_ids, 'ALLOCATED', user_name: user_name) unless pallet_ids.nil_or_empty?

      # updates allocated status
      unless pallet_ids.nil_or_empty?
        DB[:loads].where(id: load_id).update(allocated: true, allocated_at: Time.now)
        log_status('loads', load_id, 'ALLOCATED', user_name: user_name)
      end
      success_response('ok')
    end

    def remove_pallets(pallet_ids, user_name) # rubocop:disable Metrics/AbcSize
      # get un-shipped pallets and loads they represent
      ds = DB[:pallets].where(id: pallet_ids, shipped: false)
      unallocated_pallets = ds.select_map(:id)
      load_ids = ds.distinct.select_map(:load_id)

      # unallocate pallets
      unless unallocated_pallets.nil_or_empty?
        ds.update(load_id: nil, allocated: false)
        log_multiple_statuses('pallets', unallocated_pallets, 'UNALLOCATED', user_name: user_name)
      end

      # find loads still allocated
      ds = DB[:pallets].where(load_id: load_ids)
      allocated_loads = ds.distinct.select_map(:load_id)

      # log status for loads where all pallets have been unallocated
      unallocated_loads = (load_ids - allocated_loads)
      unless unallocated_loads.nil_or_empty?
        DB[:loads].where(id: unallocated_loads).update(allocated: false)
        log_multiple_statuses('loads', unallocated_loads, 'UNALLOCATED', user_name: user_name)
      end
      success_response('ok')
    end

    def allocate_pallets_from_list(load_id, res, user_name)
      pallet_numbers = res.output[:pallet_list]
      added_allocation = DB[:pallets].where(pallet_number: pallet_numbers).select_map(:id)
      add_pallets(load_id, added_allocation, user_name)
    end

    def allocate_pallets_from_multiselect(load_id, multiselect_list, user_name)
      added_allocation = DB[:pallet_sequences].where(id: multiselect_list).select_map(:pallet_id)
      current_allocation = DB[:pallets].where(load_id: load_id).select_map(:id)
      add_pallets(load_id, added_allocation - current_allocation, user_name)
      remove_pallets(current_allocation - added_allocation, user_name)
    end

    def pallets_allocated(pallet_numbers)
      DB[:pallets].where(pallet_number: pallet_numbers, allocated: true).select_map(:pallet_number)
    end

    def pallets_exists(pallet_numbers)
      DB[:pallets].where(pallet_number: pallet_numbers).select_map(:pallet_number)
    end
  end
end
