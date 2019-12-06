# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionSheetRepo < BaseRepo
    build_for_select :govt_inspection_sheets,
                     label: :id,
                     value: :id,
                     order_by: :id
    build_inactive_select :govt_inspection_sheets,
                          label: :id,
                          value: :id,
                          order_by: :id

    crud_calls_for :govt_inspection_sheets, name: :govt_inspection_sheet, wrapper: GovtInspectionSheet

    def validate_govt_inspection_sheet_inspected(id)
      pallet_ids = DB[:govt_inspection_pallets].where(govt_inspection_sheet_id: id, inspected: false).select_map(:pallet_id)
      pallet_numbers = DB[:pallets].where(id: pallet_ids).select_map(:pallet_number).join(', ')
      return failed_response("pallet, #{pallet_numbers}, results not captured") unless pallet_numbers.empty?

      ok_response
    end

    def last_record(column)
      DB[:govt_inspection_sheets].reverse(:id).limit(1).get(column)
    end
  end
end
