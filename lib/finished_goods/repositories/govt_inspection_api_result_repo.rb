# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionApiResultRepo < BaseRepo
    build_for_select :govt_inspection_api_results,
                     label: :upn_number,
                     value: :id,
                     order_by: :upn_number
    build_inactive_select :govt_inspection_api_results,
                          label: :upn_number,
                          value: :id,
                          order_by: :upn_number

    crud_calls_for :govt_inspection_api_results, name: :govt_inspection_api_result, wrapper: GovtInspectionApiResult
  end
end
