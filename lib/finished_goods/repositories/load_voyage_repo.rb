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

    crud_calls_for :load_voyages, name: :load_voyage, wrapper: LoadVoyage

    def find_load_voyage_id(load_id: nil)
      return nil if load_id.nil_or_empty?

      ds = DB[:load_voyages]
      ds = ds.where(load_id: load_id)
      ds.get(:id)
    end
  end
end
