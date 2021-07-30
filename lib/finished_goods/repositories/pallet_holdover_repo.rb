# frozen_string_literal: true

module FinishedGoodsApp
  class PalletHoldoverRepo < BaseRepo
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
