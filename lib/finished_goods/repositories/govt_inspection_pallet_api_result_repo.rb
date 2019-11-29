# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionPalletApiResultRepo < BaseRepo
    build_for_select :govt_inspection_pallet_api_results,
                     label: :id,
                     value: :id,
                     order_by: :id
    build_inactive_select :govt_inspection_pallet_api_results,
                          label: :id,
                          value: :id,
                          order_by: :id

    crud_calls_for :govt_inspection_pallet_api_results, name: :govt_inspection_pallet_api_result, wrapper: GovtInspectionPalletApiResult
  end
end
