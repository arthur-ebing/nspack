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
                                                                 year: :year } },
                                            { parent_table: :load_voyages,
                                              columns: %i[shipping_line_party_role_id
                                                          shipper_party_role_id
                                                          booking_reference
                                                          memo_pad],
                                              foreign_key: :id,
                                              flatten_columns: { shipping_line_party_role_id: :shipping_line_party_role_id,
                                                                 shipper_party_role_id: :shipper_party_role_id,
                                                                 booking_reference: :booking_reference,
                                                                 memo_pad: :memo_pad } }],
                            wrapper: LoadFlat)
    end

    def allocate_pallets_from_list(load_id, res)
      pallet_numbers = res.output[:pallet_list]
      added_allocation = DB[:pallets].where(pallet_number: pallet_numbers).select_map(:id)
      add_pallets(load_id, added_allocation)
    end

    def allocate_pallets_from_multiselect(load_id, multiselect_list)
      added_allocation = DB[:pallet_sequences].where(id: multiselect_list).select_map(:pallet_id)
      current_allocation = DB[:pallets].where(load_id: load_id).select_map(:id)
      add_pallets(load_id, added_allocation - current_allocation)
      remove_pallets(current_allocation - added_allocation)
    end

    def pallets_allocated(pallet_numbers)
      DB[:pallets]
        .where(pallet_number: pallet_numbers,
               allocated: true)
        .select_map(:pallet_number)
    end

    def pallets_exists(pallet_numbers)
      DB[:pallets]
        .where(pallet_number: pallet_numbers)
        .select_map(:pallet_number)
    end

    def add_pallets(load_id, pallet_ids)
      ds = DB[:pallets]
      ds = ds.where(id: pallet_ids,
                    allocated: false,
                    shipped: false)
      allocate_ids = ds.select_map(:id)

      ds = DB[:pallets]
      ds = ds.where(id: allocate_ids)
      ds.update(load_id: load_id,
                allocated: true,
                allocated_at: Time.now)

      log_status('loads', load_id, 'ALLOCATED')
      log_multiple_statuses('pallets', allocate_ids, 'ALLOCATED')
      success_response('ok')
    end

    def remove_pallets(pallet_ids) # rubocop:disable Metrics/AbcSize
      ds = DB[:pallets]
      ds = ds.where(id: pallet_ids,
                    shipped: false)
      unallocate_ids = ds.select_map(:id)

      ds = DB[:pallets].distinct
      ds = ds.where(id: unallocate_ids)
      load_ids = ds.select_map(:load_id)

      ds = DB[:pallets]
      ds = ds.where(id: unallocate_ids)
      ds.update(load_id: nil,
                allocated: false,
                allocated_at: nil)

      ds = DB[:pallets].distinct
      ds = ds.where(load_id: load_ids)
      allocated_load_ids = ds.select_map(:load_id)

      unallocate_load_ids = (load_ids - allocated_load_ids)
      log_multiple_statuses('loads', unallocate_load_ids, 'UNALLOCATED')
      log_multiple_statuses('pallets', unallocate_ids, 'UNALLOCATED')
      success_response('ok')
    end
  end
end
