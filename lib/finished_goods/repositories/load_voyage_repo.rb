# frozen_string_literal: true

module FinishedGoodsApp
  class LoadVoyageRepo < BaseRepo
    build_for_select :load_voyages,
                     label: :booking_reference,
                     value: :id,
                     order_by: :booking_reference
    build_inactive_select :load_voyages,
                          label: :booking_reference,
                          value: :id,
                          order_by: :booking_reference

    crud_calls_for :load_voyages, name: :load_voyage

    def find_load_voyage(id)
      find_with_association(:load_voyages, id,
                            lookup_functions: [{ function: :fn_party_role_name,
                                                 args: [:shipping_line_party_role_id],
                                                 col_name: :shipping_line },
                                               { function: :fn_party_role_name,
                                                 args: [:shipper_party_role_id],
                                                 col_name: :shipper }],
                            wrapper: LoadVoyage)
    end
  end
end
