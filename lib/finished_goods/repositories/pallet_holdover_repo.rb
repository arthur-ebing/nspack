# frozen_string_literal: true

module FinishedGoodsApp
  class PalletHoldoverRepo < BaseRepo
    build_for_select :pallet_holdovers,
                     label: :buildup_remarks,
                     value: :id,
                     no_active_check: true,
                     order_by: :buildup_remarks

    crud_calls_for :pallet_holdovers, name: :pallet_holdover

    def find_pallet_holdover(id)
      find_with_association(
        :pallet_holdovers, id,
        parent_tables: [{ parent_table: :pallets,
                          flatten_columns: { pallet_number: :pallet_number } }],
        wrapper: PalletHoldover
      )
    end
  end
end
