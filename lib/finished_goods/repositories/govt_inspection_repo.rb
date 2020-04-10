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

    def find_govt_inspection_sheet(id)
      find_with_association(:govt_inspection_sheets,
                            id,
                            lookup_functions: [{ function: :fn_consignment_note_number,
                                                 args: [id],
                                                 col_name: :consignment_note_number }],
                            wrapper: GovtInspectionSheet)
    end

    def for_select_destination_countries(active = true)
      query = <<~SQL
        SELECT country_name||' ('||destination_region_name ||')' AS code,
               dc.id
        FROM destination_countries dc
        JOIN destination_regions dr on dc.destination_region_id = dr.id
        WHERE dc.active = #{active}
        ORDER BY country_name
      SQL
      DB[query].select_map(%i[code id])
    end

    def for_select_inactive_destination_countries
      for_select_destination_countries(false)
    end

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

    def exists_on_inspection_sheet(pallet_numbers)
      ds = DB[:govt_inspection_pallets]
      ds = ds.join(:pallets, id: Sequel[:govt_inspection_pallets][:pallet_id])
      ds = ds.join(:govt_inspection_sheets, id: Sequel[:govt_inspection_pallets][:govt_inspection_sheet_id])
      ds = ds.where(cancelled: false, pallet_number: pallet_numbers)
      ds.select_map(:pallet_number)
    end

    def allocated_pallets(inspection_sheet_id)
      DB[:govt_inspection_pallets].where(govt_inspection_sheet_id: inspection_sheet_id).select_map(:pallet_id)
    end
  end
end
