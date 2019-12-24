# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionRepo < BaseRepo
    build_for_select :govt_inspection_sheets,
                     label: :id,
                     value: :id,
                     order_by: :id
    build_for_select :govt_inspection_pallets,
                     label: :failure_remarks,
                     value: :id,
                     order_by: :failure_remarks
    build_for_select :govt_inspection_api_results,
                     label: :upn_number,
                     value: :id,
                     order_by: :upn_number
    build_for_select :govt_inspection_pallet_api_results,
                     label: :id,
                     value: :id,
                     order_by: :id

    build_inactive_select :govt_inspection_sheets,
                          label: :id,
                          value: :id,
                          order_by: :id
    build_inactive_select :govt_inspection_pallets,
                          label: :failure_remarks,
                          value: :id,
                          order_by: :failure_remarks
    build_inactive_select :govt_inspection_api_results,
                          label: :upn_number,
                          value: :id,
                          order_by: :upn_number
    build_inactive_select :govt_inspection_pallet_api_results,
                          label: :id,
                          value: :id,
                          order_by: :id

    crud_calls_for :govt_inspection_sheets, name: :govt_inspection_sheet, wrapper: GovtInspectionSheet
    crud_calls_for :govt_inspection_pallets, name: :govt_inspection_pallet, wrapper: GovtInspectionPallet
    crud_calls_for :govt_inspection_api_results, name: :govt_inspection_api_result, wrapper: GovtInspectionApiResult
    crud_calls_for :govt_inspection_pallet_api_results, name: :govt_inspection_pallet_api_result, wrapper: GovtInspectionPalletApiResult

    def validate_govt_inspection_sheet_inspect_params(id)
      pallet_ids = DB[:govt_inspection_pallets].where(govt_inspection_sheet_id: id, inspected: false).select_map(:pallet_id)
      pallet_numbers = DB[:pallets].where(id: pallet_ids).select_map(:pallet_number).join(', ')
      return failed_response("Pallet: #{pallet_numbers}, results not captured.") unless pallet_numbers.empty?

      ok_response
    end

    def last_record(column)
      DB[:govt_inspection_sheets].reverse(:id).limit(1).get(column)
    end

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
                            lookup_functions: [{ function: :fn_current_status,
                                                 args: ['pallets', :pallet_id],
                                                 col_name: :status }],
                            wrapper: GovtInspectionPalletFlat)
    end

    def validate_pallet_number(pallet_number)
      id = DB[:pallets].where(pallet_number: pallet_number).get(:id)
      return failed_response("Pallet: #{pallet_number} doesn't exist.") if id.nil?

      pallet_id = DB[:govt_inspection_pallets]
                  .join(:govt_inspection_sheets, id: :govt_inspection_sheet_id)
                  .where(cancelled: false, completed: false, pallet_id: id)
                  .get(:pallet_id)
      return failed_response("Pallet: #{pallet_number} is already on an inspection sheet.") unless pallet_id.nil?

      success_response('ok', id)
    end
  end
end
