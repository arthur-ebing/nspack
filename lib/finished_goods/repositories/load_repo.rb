# frozen_string_literal: true

module FinishedGoodsApp
  class LoadRepo < BaseRepo
    build_for_select :loads, label: :order_number, value: :id, order_by: :order_number
    build_inactive_select :loads, label: :order_number, value: :id, order_by: :order_number
    crud_calls_for :loads, name: :load, wrapper: Load

    def find_load_flat(id) # rubocop:disable Metrics/AbcSize
      hash = find_with_association(:loads, id,
                                   parent_tables: [{ parent_table: :voyage_ports,
                                                     columns: %i[port_id voyage_id eta ata],
                                                     foreign_key: :pod_voyage_port_id,
                                                     flatten_columns: { port_id: :pod_port_id, voyage_id: :voyage_id, eta: :eta, ata: :ata } },
                                                   { parent_table: :voyage_ports,
                                                     columns: %i[port_id etd atd],
                                                     foreign_key: :pol_voyage_port_id,
                                                     flatten_columns: { port_id: :pol_port_id, etd: :etd, atd: :atd } },
                                                   { parent_table: :voyages,
                                                     columns: %i[voyage_type_id vessel_id voyage_number year voyage_code],
                                                     foreign_key: :voyage_id,
                                                     flatten_columns: { voyage_type_id: :voyage_type_id, vessel_id: :vessel_id, voyage_number: :voyage_number, voyage_code: :voyage_code, year: :year } }],
                                   sub_tables: [{ sub_table: :load_voyages,
                                                  columns: %i[shipping_line_party_role_id shipper_party_role_id booking_reference memo_pad],
                                                  one_to_one: { shipping_line_party_role_id: :shipping_line_party_role_id, shipper_party_role_id: :shipper_party_role_id, booking_reference: :booking_reference, memo_pad: :memo_pad } },
                                                { sub_table: :load_vehicles,
                                                  columns: %i[vehicle_number],
                                                  one_to_one: { vehicle_number: :vehicle_number } },
                                                { sub_table: :load_containers,
                                                  columns: %i[container_code],
                                                  one_to_one: { container_code: :container_code } }],
                                   lookup_functions: [{ function: :fn_current_status, args: ['loads', :id],  col_name: :status },
                                                      { function: :fn_party_role_name, args: [:customer_party_role_id], col_name: :customer },
                                                      { function: :fn_party_role_name, args: [:exporter_party_role_id], col_name: :exporter },
                                                      { function: :fn_party_role_name, args: [:billing_client_party_role_id], col_name: :billing_client },
                                                      { function: :fn_party_role_name, args: [:consignee_party_role_id], col_name: :consignee },
                                                      { function: :fn_party_role_name, args: [:final_receiver_party_role_id], col_name: :final_receiver }])
      return nil if hash.nil?

      hash[:shipping_line] = DB.get(Sequel.function(:fn_party_role_name, hash[:shipping_line_party_role_id]))
      hash[:shipper] = DB.get(Sequel.function(:fn_party_role_name, hash[:shipper_party_role_id]))
      hash[:container] = exists?(:load_containers, load_id: id)
      hash[:vehicle] = exists?(:load_vehicles, load_id: id)
      hash[:temp_tail] = DB[:pallets].where(load_id: id).exclude(temp_tail: nil).get(:temp_tail)
      hash[:temp_tail_pallet_number] = DB[:pallets].where(load_id: id).exclude(temp_tail: nil).get(:pallet_number)
      hash[:edi] = exists?(:edi_out_transactions, record_id: id)
      hash[:load_id] = id
      LoadFlat.new(hash)
    end

    def org_code_for_po(load_id)
      pr_id = DB[:loads].where(id: load_id).get(:exporter_party_role_id)
      DB.get(Sequel.function(:fn_party_role_org_code, pr_id))
    end

    def update_pallets_shipped_at(load_id, shipped_at)
      DB[:pallets].where(load_id: load_id).update(shipped_at: shipped_at)
    end

    def set_pallets_target_customer(target_customer_id, pallet_ids)
      existing_pallet_ids = select_values(:pallets, :id, target_customer_party_role_id: target_customer_id)
      removed_pallet_ids = existing_pallet_ids - pallet_ids
      new_pallet_ids = pallet_ids - existing_pallet_ids
      DB[:pallets].where(id: removed_pallet_ids).update(target_customer_party_role_id: nil)
      DB[:pallets].where(id: new_pallet_ids).update(target_customer_party_role_id: target_customer_id)
    end

    def allocate_pallets(load_id, pallet_ids, user)
      return if pallet_ids.nil_or_empty?

      allocated_length = select_values(:pallets, :id, load_id: load_id).length
      raise Crossbeams::InfoError, 'Allocation exceeded max pallets on load' if (allocated_length + pallet_ids.length) > AppConst::MAX_PALLETS_ON_LOAD

      update(:pallets, pallet_ids, load_id: load_id, allocated: true, allocated_at: Time.now)
      log_multiple_statuses(:pallets, pallet_ids, 'ALLOCATED', user_name: user.user_name)

      # updates load status allocated
      update(:loads, load_id, allocated: true, allocated_at: Time.now)
      log_status(:loads, load_id, 'ALLOCATED', user_name: user.user_name)
    end

    def unallocate_pallets(pallet_ids, user)
      return if pallet_ids.nil_or_empty?

      load_ids = select_values(:pallets, :load_id, id: pallet_ids).uniq
      update(:pallets, pallet_ids, load_id: nil, allocated: false, temp_tail: nil)
      log_multiple_statuses(:pallets, pallet_ids, 'UNALLOCATED', user_name: user.user_name)

      # log status for loads where all pallets have been unallocated
      load_ids.each do |load_id|
        unless exists?(:pallets, load_id: load_id)
          update(:loads, load_id, allocated: false)
          log_status(:loads, load_id, 'UNALLOCATED', user_name: user.user_name)
        end
      end
    end
  end
end
