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

    def update_load_pallets(load_id, multiselect_list)
      added_allocation = DB[:vw_pallet_sequence_flat].where(id: multiselect_list).map { |rec| rec[:pallet_id] }
      current_allocation = DB[:pallets].where(load_id: load_id).map { |rec| rec[:id] }

      add_pallets(added_allocation - current_allocation, load_id)
      remove_pallets(current_allocation - added_allocation)
    end

    def add_pallets(pallet_ids, load_id)
      pallet_ids.each do |pallet_id|
        ds = DB[:pallets]
        ds = ds.where(id: pallet_id,
                      shipped: false)
        ds.update(load_id: load_id,
                  allocated: true,
                  allocated_at: Time.now)
        log_status('pallets', pallet_id, 'LOAD_ADDED')
      end
    end

    def remove_pallets(pallet_ids)
      pallet_ids.each do |pallet_id|
        ds = DB[:pallets]
        ds = ds.where(id: pallet_id,
                      shipped: false)
        ds.update(load_id: nil,
                  allocated: false,
                  allocated_at: nil)
        log_status('pallets', pallet_id, 'LOAD_REMOVED')
      end
    end
  end
end
