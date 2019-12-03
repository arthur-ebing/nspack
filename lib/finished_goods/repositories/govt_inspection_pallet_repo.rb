# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionPalletRepo < BaseRepo
    build_for_select :govt_inspection_pallets,
                     label: :failure_remarks,
                     value: :id,
                     order_by: :failure_remarks
    build_inactive_select :govt_inspection_pallets,
                          label: :failure_remarks,
                          value: :id,
                          order_by: :failure_remarks

    crud_calls_for :govt_inspection_pallets, name: :govt_inspection_pallet, wrapper: GovtInspectionPallet

    def find_govt_inspection_pallet_flat(id)
      find_with_association(:govt_inspection_pallets,
                            id,
                            parent_tables: [{ parent_table: :inspection_failure_reasons,
                                              columns: %i[failure_reason description main_factor secondary_factor],
                                              foreign_key: :failure_reason_id,
                                              flatten_columns: { failure_reason: :failure_reason,
                                                                 description: :description,
                                                                 main_factor: :main_factor,
                                                                 secondary_factor: :secondary_factor } }],
                            wrapper: GovtInspectionPalletFlat)
    end

    def for_select_pallets
      DB[:pallets].where(active: true).select_map(%i[pallet_number id])
    end

    def for_select_inactive_pallets
      DB[:pallets].where(active: false).select_map(%i[pallet_number id])
    end

    def validate_pallet_number(pallet_number)
      id = DB[:pallets].where(pallet_number: pallet_number).get(:id)
      return failed_response("pallet: #{pallet_number} doesn't exist") if id.nil?

      pallet_id = DB[:govt_inspection_pallets].where(pallet_id: id).get(:pallet_id)
      return failed_response("pallet: #{pallet_number} is already on a inspection sheet") unless pallet_id.nil?

      success_response('ok', id)
    end
  end
end
