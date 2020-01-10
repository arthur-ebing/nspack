# frozen_string_literal: true

module FinishedGoodsApp
  class LoadRepo < BaseRepo # rubocop:disable Metrics/ClassLength
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
                                              columns: %i[port_id voyage_id eta ata],
                                              foreign_key: :pol_voyage_port_id,
                                              flatten_columns: { port_id: :pol_port_id, voyage_id: :voyage_id, eta: :eta, ata: :ata } },
                                            { parent_table: :voyage_ports,
                                              columns: %i[port_id etd atd],
                                              foreign_key: :pod_voyage_port_id,
                                              flatten_columns: { port_id: :pod_port_id, etd: :etd, atd: :atd } },
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
                            lookup_functions: [{ function: :fn_current_status,
                                                 args: ['loads', id],
                                                 col_name: :status }],
                            wrapper: LoadFlat)
    end

    def last_load(exclude_shipped: false)
      ds = DB[:loads].order(:updated_at)
      ds = ds.exclude(shipped: true) if exclude_shipped
      ds.reverse.limit(1).get(:id)
    end

    def get_location_id_by_barcode(location_barcode)
      DB[:locations].where(location_short_code: location_barcode).get(:id)
    end

    def find_pallet_numbers_from(args)
      ds = DB[:pallets]
      ds = ds.where(id: DB[:pallet_sequences].where(id: args.delete(:pallet_sequence_id)).select_map(:pallet_id)) if args.key?(:pallet_sequence_id)
      ds = ds.where(args) unless args.nil_or_empty?
      ds.select_map(:pallet_number).flatten
    end

    def find_pallet_ids_from(args)
      ds = DB[:pallets]
      ds = ds.where(id: DB[:pallet_sequences].where(id: args.delete(:pallet_sequence_id)).select_map(:pallet_id)) if args.key?(:pallet_sequence_id)
      ds = ds.where(args) unless args.nil_or_empty?
      ds.select_map(:id).flatten
    end

    def where_pallets(pallet_numbers, allocated: nil, shipped: nil, has_nett_weight: false, has_gross_weight: false)
      ds = DB[:pallets].where(pallet_number: pallet_numbers)
      ds = ds.where(allocated: allocated) unless allocated.nil?
      ds = ds.where(shipped: shipped) unless shipped.nil?
      ds = ds.exclude { nett_weight.> 0 } if has_nett_weight # rubocop:disable Style/NumericPredicate
      ds = ds.exclude { gross_weight.> 0 } if has_gross_weight # rubocop:disable Style/NumericPredicate
      ds.select_map(:pallet_number)
    end

    def allocate_pallets(load_id, pallet_ids, user_name)
      return ok_response if pallet_ids.empty?

      DB[:pallets].where(id: pallet_ids).update(load_id: load_id, allocated: true, allocated_at: Time.now)
      log_multiple_statuses(:pallets, pallet_ids, 'ALLOCATED', user_name: user_name)

      # updates load status allocated
      DB[:loads].where(id: load_id).update(allocated: true, allocated_at: Time.now)
      log_status(:loads, load_id, 'ALLOCATED', user_name: user_name)

      ok_response
    end

    def unallocate_pallets(load_id, pallet_ids, user_name) # rubocop:disable Metrics/AbcSize
      return ok_response if pallet_ids.empty?

      DB[:pallets].where(id: pallet_ids).update(load_id: nil, allocated: false, shipped_at: nil)
      log_multiple_statuses(:pallets, pallet_ids, 'UNALLOCATED', user_name: user_name)

      # find unallocated loads
      allocated_load_ids = DB[:pallets].where(load_id: load_id).distinct.select_map(:load_id)
      unallocated_load_ids = [load_id] - allocated_load_ids

      # log status for loads where all pallets have been unallocated
      unless unallocated_load_ids.empty?
        DB[:loads].where(id: unallocated_load_ids).update(allocated: false)
        log_multiple_statuses(:loads, unallocated_load_ids, 'UNALLOCATED', user_name: user_name)
      end

      ok_response
    end

    def org_code_for_po(load_id)
      pr_id = DB[:loads].where(id: load_id).get(:exporter_party_role_id)
      DB.get(Sequel.function(:fn_party_role_name, pr_id))
      # MasterfilesApp::PartyRepo.new.org_code_for_party_role(pr_id)
    end

    def update_pallets_shipped_at(load_id:, shipped_at:)
      DB[:pallets].where(load_id: load_id).update(shipped_at: shipped_at)
    end
  end
end
